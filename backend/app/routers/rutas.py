from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from ..db.database import get_db
from ..core.security import get_current_user, require_role
from ..models.models import RutaEntrega, Pedido
from ..schemas.schemas import RutaCreate, RutaUpdate, RutaResponse

router = APIRouter(prefix="/rutas", tags=["rutas"])

@router.get("/", response_model=List[RutaResponse])
async def listar_rutas(db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "repartidor"]))):
    return db.query(RutaEntrega).all()

@router.post("/", response_model=RutaResponse)
async def crear_ruta(data: RutaCreate, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "repartidor"]))):
    pedido = db.query(Pedido).filter(Pedido.id == data.pedido_id).first()
    if not pedido:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    if db.query(RutaEntrega).filter(RutaEntrega.pedido_id == data.pedido_id).first():
        raise HTTPException(status_code=400, detail="Ruta ya existe para este pedido")
    ruta = RutaEntrega(pedido_id=data.pedido_id, repartidor_id=data.repartidor_id, fecha_salida=data.fecha_salida)
    db.add(ruta)
    db.commit()
    db.refresh(ruta)
    return ruta

@router.put("/{ruta_id}", response_model=RutaResponse)
async def actualizar_ruta(ruta_id: int, data: RutaUpdate, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "repartidor"]))):
    ruta = db.query(RutaEntrega).filter(RutaEntrega.id == ruta_id).first()
    if not ruta:
        raise HTTPException(status_code=404, detail="No encontrado")
    if data.estado:
        ruta.estado = data.estado
    if data.fecha_entrega:
        ruta.fecha_entrega = data.fecha_entrega
    db.commit()
    db.refresh(ruta)
    return ruta