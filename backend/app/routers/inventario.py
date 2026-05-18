from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List
from ..db.database import get_db
from ..core.security import get_current_user, require_role
from ..models.models import Inventario, Producto
from ..schemas.schemas import InventarioUpdate, InventarioResponse

router = APIRouter(prefix="/inventario", tags=["inventario"])

@router.get("/", response_model=List[InventarioResponse])
async def listar_inventario(skip: int = Query(0, ge=0), limit: int = Query(100, ge=1, le=500), db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "bodega", "vendedor"]))):
    return db.query(Inventario).join(Producto).filter(Producto.activo == True).offset(skip).limit(limit).all()

@router.get("/{prod_id}", response_model=InventarioResponse)
async def obtener_inventario(prod_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    inv = db.query(Inventario).filter(Inventario.producto_id == prod_id).first()
    if not inv:
        raise HTTPException(status_code=404, detail="No encontrado")
    return inv

@router.put("/{prod_id}", response_model=InventarioResponse)
async def actualizar_inventario(prod_id: int, data: InventarioUpdate, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "bodega"]))):
    inv = db.query(Inventario).filter(Inventario.producto_id == prod_id).first()
    if not inv:
        raise HTTPException(status_code=404, detail="No encontrado")
    if data.cantidad is not None:
        inv.cantidad = data.cantidad
    if data.stock_minimo is not None:
        inv.stock_minimo = data.stock_minimo
    db.commit()
    db.refresh(inv)
    return inv