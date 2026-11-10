from datetime import datetime
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, UniqueConstraint
from core.database import Base


class InvitacionCuidado(Base):
    __tablename__ = "invitaciones_cuidado"
    __table_args__ = (UniqueConstraint("mascota_id", "invitado_id"),)

    id = Column(Integer, primary_key=True, index=True)
    mascota_id = Column(Integer, ForeignKey("mascotas.id", ondelete="CASCADE"), nullable=False)
    invitador_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    invitado_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)
    permiso = Column(String(16), nullable=False)
    estado = Column(String(16), nullable=False, default="pendiente")
    creada_en = Column(DateTime, nullable=False, default=datetime.utcnow)
    respondida_en = Column(DateTime, nullable=True)
    revocada_en = Column(DateTime, nullable=True)
