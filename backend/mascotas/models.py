from sqlalchemy import Column, Integer, String, Boolean, Date, ForeignKey
from sqlalchemy.orm import relationship
from core.database import Base

class Mascota(Base):
    __tablename__ = "mascotas"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String)
    tipo = Column(String)
    cuidado = Column(String)
    fecha = Column(Date)
    estado = Column(Boolean, default = False)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"))
    responsable_id = Column(Integer, ForeignKey("usuarios.id"), nullable=True)
    responsable = relationship("UsuarioDB", foreign_keys=[responsable_id])

    @property
    def responsable_nombre(self):
        return self.responsable.nombre if self.responsable else None

    @property
    def responsable_correo(self):
        return self.responsable.correo if self.responsable else None