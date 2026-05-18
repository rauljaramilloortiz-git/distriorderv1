from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List
from ..db.database import get_db
from ..core.security import get_current_user, require_role
from ..models.models import Producto, Inventario
from ..schemas.schemas import ProductoCreate, ProductoResponse

router = APIRouter(prefix="/productos", tags=["productos"])

@router.get("/", response_model=List[ProductoResponse])
async def listar_productos(skip: int = Query(0, ge=0), limit: int = Query(100, ge=1, le=500), db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    return db.query(Producto).filter(Producto.activo == True).offset(skip).limit(limit).all()

@router.get("/{prod_id}", response_model=ProductoResponse)
async def obtener_producto(prod_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    prod = db.query(Producto).filter(Producto.id == prod_id).first()
    if not prod:
        raise HTTPException(status_code=404, detail="No encontrado")
    return prod

@router.post("/", response_model=ProductoResponse)
async def crear_producto(data: ProductoCreate, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "bodega"]))):
    prod = Producto(**data.model_dump())
    db.add(prod)
    db.commit()
    db.refresh(prod)
    inv = Inventario(producto_id=prod.id, cantidad=0)
    db.add(inv)
    db.commit()
    return prod

@router.put("/{prod_id}", response_model=ProductoResponse)
async def actualizar_producto(prod_id: int, data: ProductoCreate, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "bodega"]))):
    prod = db.query(Producto).filter(Producto.id == prod_id).first()
    if not prod:
        raise HTTPException(status_code=404, detail="No encontrado")
    for key, value in data.model_dump().items():
        setattr(prod, key, value)
    db.commit()
    db.refresh(prod)
    return prod