from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import auth, usuarios, clientes, categorias, productos, inventario, pedidos, facturas, pagos, rutas, dashboard, reportes
from .db.database import engine, Base

app = FastAPI(title="API Distribuidora", version="1.0.0")

app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"]
)

app.include_router(auth.router)
app.include_router(usuarios.router)
app.include_router(clientes.router)
app.include_router(categorias.router)
app.include_router(productos.router)
app.include_router(inventario.router)
app.include_router(pedidos.router)
app.include_router(facturas.router)
app.include_router(pagos.router)
app.include_router(rutas.router)
app.include_router(dashboard.router)
app.include_router(reportes.router)

@app.on_event("startup")
def onstartup():
    Base.metadata.create_all(bind=engine)

@app.get("/")
def root():
    return {"message": "API Distribuidora funcionando", "version": "1.0.0"}

@app.get("/health")
def health():
    return {"status": "ok"}