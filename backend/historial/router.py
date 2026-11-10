from fastapi import APIRouter, Depends
from sqlalchemy import or_
from sqlalchemy.orm import Session
from core.database import get_db
from . import models, schemas
from mascotas.models import Mascota
from compartidos.models import InvitacionCuidado
from typing import Optional

from usuarios.router import obtener_usuario_token

router = APIRouter()

@router.get("/", response_model=list[schemas.Evento])
def mi_historial(
    tipo: Optional[str] = None,
    db: Session = Depends(get_db),
    usuario = Depends(obtener_usuario_token)
):
    invitadas = db.query(InvitacionCuidado.mascota_id).filter(
        InvitacionCuidado.invitado_id == usuario.id,
        InvitacionCuidado.estado == "aceptada"
    )
    accesibles = db.query(Mascota.id).filter(or_(
        Mascota.usuario_id == usuario.id,
        Mascota.responsable_id == usuario.id,
        Mascota.id.in_(invitadas)
    ))
    query = db.query(models.Evento).filter(or_(
        models.Evento.usuario_id == usuario.id,
        models.Evento.mascota_id.in_(accesibles)
    ))
    if tipo:
        query = query.filter(models.Evento.tipo == tipo)
    # El más reciente primero
    eventos = query.order_by(models.Evento.fecha_hora.desc(), models.Evento.id.desc()).all()
    return eventos
