from datetime import date, timedelta
from types import SimpleNamespace

import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from core.database import Base
from usuarios.models import UsuarioDB
from mascotas.models import Mascota
from historial.models import Evento
from compartidos.models import InvitacionCuidado
from compartidos.router import invitar, responder, cambiar_permiso, revocar, listar_invitaciones
from compartidos.schemas import InvitacionCrear, InvitacionRespuesta, CambioPermiso
from mascotas.router import completar_cuidado, editar_mascota, mis_mascotas
from mascotas.schemas import MascotaCreate
from historial.router import mi_historial


@pytest.fixture
def datos():
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    Base.metadata.create_all(engine)
    with Session(engine) as db:
        dueno = UsuarioDB(nombre="Dueño", correo="dueno@example.com", password="123")
        responsable = UsuarioDB(nombre="Responsable", correo="responsable@example.com", password="123")
        invitada = UsuarioDB(nombre="Invitada", correo="invitada@example.com", password="123")
        ajeno = UsuarioDB(nombre="Ajeno", correo="ajeno@example.com", password="123")
        db.add_all([dueno, responsable, invitada, ajeno])
        db.commit()
        cuidado = Mascota(
            nombre="Luna", tipo="Perro", cuidado="Vacuna",
            fecha=date.today() + timedelta(days=5), estado=False,
            usuario_id=dueno.id, responsable_id=responsable.id, periodicidad_dias=3
        )
        db.add(cuidado)
        db.commit()
        yield db, dueno, responsable, invitada, ajeno, cuidado
    engine.dispose()


def mascotas_visibles(db, usuario):
    return mis_mascotas(
        nombre=None, estado=None, cuidado=None, fecha_inicio=None, fecha_fin=None,
        db=db, usuario=usuario
    )


def error_http(codigo, accion):
    with pytest.raises(HTTPException) as error:
        accion()
    assert error.value.status_code == codigo


def test_consulta_gestion_revocacion_y_autoria(datos):
    db, dueno, responsable, invitada, ajeno, cuidado = datos

    error_http(403, lambda: invitar(
        InvitacionCrear(mascota_id=cuidado.id, invitado_correo=invitada.correo, permiso="consulta"),
        db=db, usuario=dueno
    ))

    invitacion = invitar(
        InvitacionCrear(mascota_id=cuidado.id, invitado_correo=invitada.correo, permiso="consulta"),
        db=db, usuario=responsable
    )
    assert invitacion["estado"] == "pendiente"
    assert len(listar_invitaciones(db=db, usuario=invitada)) == 1
    assert mascotas_visibles(db, invitada) == []

    responder(invitacion["id"], InvitacionRespuesta(aceptar=True), db=db, usuario=invitada)
    cuidado_visible = mascotas_visibles(db, invitada)[0]
    assert cuidado_visible.permiso_compartido == "consulta"
    assert not cuidado_visible.puede_marcar
    assert not cuidado_visible.puede_editar
    error_http(403, lambda: completar_cuidado(cuidado.id, db=db, usuario=invitada))
    error_http(403, lambda: editar_mascota(
        cuidado.id,
        MascotaCreate(nombre="Luna", tipo="Perro", cuidado="Control",
                      fecha=cuidado.fecha, responsable_correo=responsable.correo),
        db=db, usuario=invitada
    ))
    error_http(403, lambda: cambiar_permiso(
        invitacion["id"], CambioPermiso(permiso="gestion"), db=db, usuario=dueno
    ))

    cambiar_permiso(invitacion["id"], CambioPermiso(permiso="gestion"), db=db, usuario=responsable)
    cuidado_visible = mascotas_visibles(db, invitada)[0]
    assert cuidado_visible.puede_marcar and cuidado_visible.puede_editar
    assert not cuidado_visible.puede_eliminar
    fecha_anterior = cuidado.fecha
    completar_cuidado(cuidado.id, db=db, usuario=invitada)
    db.refresh(cuidado)
    assert cuidado.fecha == fecha_anterior + timedelta(days=3)
    assert not cuidado.estado

    evento = db.query(Evento).filter(Evento.mascota_id == cuidado.id, Evento.tipo == "realizado").one()
    assert evento.autor_id == invitada.id
    assert evento.autor_nombre == "Invitada"
    assert evento.fecha_hora is not None
    assert mi_historial(tipo=None, db=db, usuario=invitada)[0].id == evento.id

    revocar(invitacion["id"], db=db, usuario=responsable)
    assert mascotas_visibles(db, invitada) == []
    assert mi_historial(tipo=None, db=db, usuario=invitada) == []
    error_http(404, lambda: completar_cuidado(cuidado.id, db=db, usuario=invitada))
    assert mi_historial(tipo=None, db=db, usuario=dueno)[0].autor_nombre == "Invitada"
    assert mi_historial(tipo=None, db=db, usuario=responsable)[0].autor_id == invitada.id
    error_http(403, lambda: revocar(invitacion["id"], db=db, usuario=ajeno))


def test_rechazo_y_reinvitacion(datos):
    db, _, responsable, invitada, _, cuidado = datos
    invitacion = invitar(
        InvitacionCrear(mascota_id=cuidado.id, invitado_correo=invitada.correo, permiso="gestion"),
        db=db, usuario=responsable
    )
    responder(invitacion["id"], InvitacionRespuesta(aceptar=False), db=db, usuario=invitada)
    assert mascotas_visibles(db, invitada) == []
    error_http(409, lambda: responder(
        invitacion["id"], InvitacionRespuesta(aceptar=True), db=db, usuario=invitada
    ))
    reinvitacion = invitar(
        InvitacionCrear(mascota_id=cuidado.id, invitado_correo=invitada.correo, permiso="consulta"),
        db=db, usuario=responsable
    )
    assert reinvitacion["id"] == invitacion["id"]
    assert reinvitacion["estado"] == "pendiente"
    revocar(reinvitacion["id"], db=db, usuario=responsable)
    assert mascotas_visibles(db, invitada) == []
    assert db.query(InvitacionCuidado).filter(
        InvitacionCuidado.mascota_id == cuidado.id
    ).count() == 1
