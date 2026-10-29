from fastapi import FastAPI
from sqlalchemy import text
from fastapi.middleware.cors import CORSMiddleware
from core.database import engine, Base
from usuarios.router import router as usuarios_router
from mascotas.router import router as mascotas_router
from historial.router import router as historial_router
# Crear las tablas automáticamente al iniciar
Base.metadata.create_all(bind=engine)
with engine.begin() as connection:
    connection.execute(text(
        "ALTER TABLE mascotas ADD COLUMN IF NOT EXISTS responsable_id INTEGER REFERENCES usuarios(id)"
    ))

app = FastAPI(title="Mascota al Día API", version="1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(usuarios_router, prefix="/api/usuarios", tags=["Usuarios"])
app.include_router(mascotas_router, prefix="/api/mascotas", tags=["Mascotas"])
app.include_router(historial_router, prefix="/api/historial", tags=["Historial"])

@app.get("/")
def root():
    return {"estado": "API funcionando correctamente"}