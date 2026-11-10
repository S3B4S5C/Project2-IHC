from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session

from core.database import get_db
from usuarios.models import UsuarioDB
from usuarios.router import obtener_usuario_token
from mascotas.models import Mascota
from .models import InvitacionCuidado
from .permisos import puede_administrar
from . import schemas


router = APIRouter()


def _cuidado(db, id):
    cuidado = db.query(Mascota).filter(Mascota.id == id).first()
    if not cuidado:
        raise HTTPException(status_code=404, detail="Cuidado no encontrado")
    return cuidado


def _invitacion(db, id):
    invitacion = db.query(InvitacionCuidado).filter(InvitacionCuidado.id == id).first()
    if not invitacion:
        raise HTTPException(status_code=404, detail="Invitación no encontrada")
    return invitacion


def _solo_responsable(cuidado, usuario):
    if not puede_administrar(cuidado, usuario.id):
        raise HTTPException(status_code=403, detail="Solo el responsable administra accesos")


def _detalle(db, invitacion, usuario_id):
    cuidado = _cuidado(db, invitacion.mascota_id)
    invitado = db.query(UsuarioDB).filter(UsuarioDB.id == invitacion.invitado_id).first()
    invitador = db.query(UsuarioDB).filter(UsuarioDB.id == invitacion.invitador_id).first()
    return {
        "id": invitacion.id,
        "mascota_id": cuidado.id,
        "mascota_nombre": cuidado.nombre,
        "cuidado": cuidado.cuidado,
        "invitado_nombre": invitado.nombre,
        "invitado_correo": invitado.correo,
        "invitador_nombre": invitador.nombre,
        "permiso": invitacion.permiso,
        "estado": invitacion.estado,
        "creada_en": invitacion.creada_en,
        "respondida_en": invitacion.respondida_en,
        "revocada_en": invitacion.revocada_en,
        "recibida": invitacion.invitado_id == usuario_id,
        "puede_administrar": puede_administrar(cuidado, usuario_id),
    }


@router.get("/invitaciones", response_model=list[schemas.InvitacionDetalle])
def listar_invitaciones(db: Session = Depends(get_db), usuario=Depends(obtener_usuario_token)):
    invitaciones = db.query(InvitacionCuidado).filter(or_(
        InvitacionCuidado.invitador_id == usuario.id,
        InvitacionCuidado.invitado_id == usuario.id
    )).order_by(InvitacionCuidado.creada_en.desc(), InvitacionCuidado.id.desc()).all()
    resultado = []
    for invitacion in invitaciones:
        cuidado = db.query(Mascota).filter(Mascota.id == invitacion.mascota_id).first()
        if cuidado and (invitacion.invitado_id == usuario.id or puede_administrar(cuidado, usuario.id)):
            resultado.append(_detalle(db, invitacion, usuario.id))
    return resultado


@router.post("/invitar", response_model=schemas.InvitacionDetalle, status_code=201)
def invitar(datos: schemas.InvitacionCrear, db: Session = Depends(get_db), usuario=Depends(obtener_usuario_token)):
    cuidado = _cuidado(db, datos.mascota_id)
    _solo_responsable(cuidado, usuario)
    invitado = db.query(UsuarioDB).filter(UsuarioDB.correo == datos.invitado_correo).first()
    if not invitado:
        raise HTTPException(status_code=400, detail="El correo no pertenece a un usuario registrado")
    if invitado.id in (cuidado.usuario_id, cuidado.responsable_id):
        raise HTTPException(status_code=400, detail="No puedes invitar al dueño o al responsable")

    invitacion = db.query(InvitacionCuidado).filter(
        InvitacionCuidado.mascota_id == cuidado.id,
        InvitacionCuidado.invitado_id == invitado.id
    ).first()
    if invitacion and invitacion.estado in ("pendiente", "aceptada"):
        raise HTTPException(status_code=409, detail="Ya existe una invitación activa para esta persona")

    if invitacion:
        invitacion.invitador_id = usuario.id
        invitacion.permiso = datos.permiso
        invitacion.estado = "pendiente"
        invitacion.creada_en = datetime.utcnow()
        invitacion.respondida_en = None
        invitacion.revocada_en = None
    else:
        invitacion = InvitacionCuidado(
            mascota_id=cuidado.id,
            invitador_id=usuario.id,
            invitado_id=invitado.id,
            permiso=datos.permiso,
            estado="pendiente"
        )
        db.add(invitacion)
    db.commit()
    db.refresh(invitacion)
    return _detalle(db, invitacion, usuario.id)


@router.post("/{id}/responder", response_model=schemas.InvitacionDetalle)
def responder(id: int, datos: schemas.InvitacionRespuesta, db: Session = Depends(get_db), usuario=Depends(obtener_usuario_token)):
    invitacion = _invitacion(db, id)
    if invitacion.invitado_id != usuario.id:
        raise HTTPException(status_code=403, detail="Solo la persona invitada puede responder")
    if invitacion.estado != "pendiente":
        raise HTTPException(status_code=409, detail="Esta invitación ya fue respondida o revocada")
    invitacion.estado = "aceptada" if datos.aceptar else "rechazada"
    invitacion.respondida_en = datetime.utcnow()
    db.commit()
    db.refresh(invitacion)
    return _detalle(db, invitacion, usuario.id)


@router.patch("/{id}/permiso", response_model=schemas.InvitacionDetalle)
def cambiar_permiso(id: int, datos: schemas.CambioPermiso, db: Session = Depends(get_db), usuario=Depends(obtener_usuario_token)):
    invitacion = _invitacion(db, id)
    _solo_responsable(_cuidado(db, invitacion.mascota_id), usuario)
    if invitacion.estado not in ("pendiente", "aceptada"):
        raise HTTPException(status_code=409, detail="La invitación no está activa")
    invitacion.permiso = datos.permiso
    db.commit()
    db.refresh(invitacion)
    return _detalle(db, invitacion, usuario.id)


@router.post("/{id}/revocar", response_model=schemas.InvitacionDetalle)
def revocar(id: int, db: Session = Depends(get_db), usuario=Depends(obtener_usuario_token)):
    invitacion = _invitacion(db, id)
    _solo_responsable(_cuidado(db, invitacion.mascota_id), usuario)
    if invitacion.estado not in ("pendiente", "aceptada"):
        raise HTTPException(status_code=409, detail="La invitación no está activa")
    invitacion.estado = "revocada"
    invitacion.revocada_en = datetime.utcnow()
    db.commit()
    db.refresh(invitacion)
    return _detalle(db, invitacion, usuario.id)
