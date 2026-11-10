from .models import InvitacionCuidado


def puede_administrar(mascota, usuario_id):
    return (mascota.responsable_id or mascota.usuario_id) == usuario_id


def invitacion_aceptada(db, mascota_id, usuario_id):
    return db.query(InvitacionCuidado).filter(
        InvitacionCuidado.mascota_id == mascota_id,
        InvitacionCuidado.invitado_id == usuario_id,
        InvitacionCuidado.estado == "aceptada"
    ).first()


def permiso_usuario(db, mascota, usuario_id):
    if usuario_id in (mascota.usuario_id, mascota.responsable_id):
        return "gestion"
    invitacion = invitacion_aceptada(db, mascota.id, usuario_id)
    return invitacion.permiso if invitacion else None


def puede_editar(db, mascota, usuario_id):
    if mascota.usuario_id == usuario_id:
        return True
    invitacion = invitacion_aceptada(db, mascota.id, usuario_id)
    return bool(invitacion and invitacion.permiso == "gestion")
