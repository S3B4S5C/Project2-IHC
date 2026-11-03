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

    class Config:
        orm_mode=True