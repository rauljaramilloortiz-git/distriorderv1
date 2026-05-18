from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List
from ..db.database import get_db
from ..core.security import get_current_user, require_role
from ..models.models import Usuario
from ..schemas.schemas import UsuarioResponse, UsuarioCreate

router = APIRouter(prefix="/usuarios", tags=["usuarios"])

@router.get("/", response_model=List[UsuarioResponse])
async def listar_usuarios(skip: int = Query(0, ge=0), limit: int = Query(100, ge=1, le=500), db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin"]))):
    return db.query(Usuario).offset(skip).limit(limit).all()

@router.get("/{user_id}", response_model=UsuarioResponse)
async def obtener_usuario(user_id: int, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin"]))):
    user = db.query(Usuario).filter(Usuario.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="No encontrado")
    return user

@router.put("/{user_id}", response_model=UsuarioResponse)
async def actualizar_usuario(user_id: int, data: UsuarioCreate, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin"]))):
    user = db.query(Usuario).filter(Usuario.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="No encontrado")
    user.nombre = data.nombre
    user.email = data.email
    user.rol = data.rol
    db.commit()
    db.refresh(user)
    return user

@router.delete("/{user_id}")
async def eliminar_usuario(user_id: int, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin"]))):
    user = db.query(Usuario).filter(Usuario.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="No encontrado")
    user.activo = False
    db.commit()
    return {"message": "Usuario desactivado"}