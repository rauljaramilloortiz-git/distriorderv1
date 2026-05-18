from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List
from ..db.database import get_db
from ..core.security import get_current_user, require_role
from ..models.models import Categoria
from ..schemas.schemas import CategoriaCreate, CategoriaResponse

router = APIRouter(prefix="/categorias", tags=["categorias"])

@router.get("/", response_model=List[CategoriaResponse])
async def listar_categorias(skip: int = Query(0, ge=0), limit: int = Query(100, ge=1, le=500), db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    return db.query(Categoria).filter(Categoria.activo == True).offset(skip).limit(limit).all()

@router.post("/", response_model=CategoriaResponse)
async def crear_categoria(data: CategoriaCreate, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "bodega"]))):
    cat = Categoria(**data.model_dump())
    db.add(cat)
    db.commit()
    db.refresh(cat)
    return cat

@router.put("/{cat_id}", response_model=CategoriaResponse)
async def actualizar_categoria(cat_id: int, data: CategoriaCreate, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "bodega"]))):
    cat = db.query(Categoria).filter(Categoria.id == cat_id).first()
    if not cat:
        raise HTTPException(status_code=404, detail="No encontrado")
    for key, value in data.model_dump().items():
        setattr(cat, key, value)
    db.commit()
    db.refresh(cat)
    return cat