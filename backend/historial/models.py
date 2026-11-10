from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from datetime import datetime
from core.database import Base

class Evento(Base):
    __tablename__ = "eventos"
    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"))
    # Sin ForeignKey para que el evento quede aunque se elimine el cuidado
    mascota_id = Column(Integer)
    mascota_nombre = Column(String)
    cuidado = Column(String)
    tipo = Column(String)  # "realizado" o "reprogramado"
    detalle = Column(String)
    fecha_hora = Column(DateTime, default=datetime.now)
    autor_id = Column(Integer, ForeignKey("usuarios.id"), nullable=True)
    autor_nombre = Column(String, nullable=True)
