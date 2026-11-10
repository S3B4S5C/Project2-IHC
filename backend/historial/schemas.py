from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class Evento(BaseModel):
    id: int
    mascota_id: int
    mascota_nombre: str
    cuidado: str
    tipo: str
    detalle: str
    fecha_hora: datetime
    autor_id: Optional[int] = None
    autor_nombre: Optional[str] = None

    class Config:
        orm_mode=True
