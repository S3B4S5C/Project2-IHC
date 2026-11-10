from pydantic import BaseModel, Field
from datetime import date
from typing import Optional

class MascotaCreate(BaseModel):
    nombre: str
    tipo: str
    cuidado: str
    fecha: date
    responsable_correo: Optional[str] = None
    periodicidad_dias: Optional[int] = Field(default=None, ge=1)

class Mascota(BaseModel):
    id: int 
    nombre: str
    tipo: str
    cuidado: str
    fecha: date
    estado: bool
    usuario_id: int
    responsable_id: Optional[int] = None
    periodicidad_dias: Optional[int] = None
    responsable_nombre: Optional[str] = None
    responsable_correo: Optional[str] = None
    puede_editar: bool = True
    puede_marcar: bool = True
    puede_eliminar: bool = True
    puede_administrar_accesos: bool = False
    permiso_compartido: Optional[str] = None

    class Config:
        orm_mode=True