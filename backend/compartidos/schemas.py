from datetime import datetime
from typing import Literal, Optional
from pydantic import BaseModel, EmailStr


Permiso = Literal["consulta", "gestion"]


class InvitacionCrear(BaseModel):
    mascota_id: int
    invitado_correo: EmailStr
    permiso: Permiso


class InvitacionRespuesta(BaseModel):
    aceptar: bool


class CambioPermiso(BaseModel):
    permiso: Permiso


class InvitacionDetalle(BaseModel):
    id: int
    mascota_id: int
    mascota_nombre: str
    cuidado: str
    invitado_nombre: str
    invitado_correo: str
    invitador_nombre: str
    permiso: Permiso
    estado: str
    creada_en: datetime
    respondida_en: Optional[datetime]
    revocada_en: Optional[datetime]
    recibida: bool
    puede_administrar: bool
