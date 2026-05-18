from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List
from ..db.database import get_db
from ..core.security import get_current_user, require_role
from ..models.models import Cliente, Usuario, Role
from ..schemas.schemas import ClienteCreate, ClienteResponse

router = APIRouter(prefix="/clientes", tags=["clientes"])

@router.get("/", response_model=List[ClienteResponse])
async def listar_clientes(skip: int = Query(0, ge=0), limit: int = Query(100, ge=1, le=500), db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user["role"] == "cliente":
        usuario = db.query(Usuario).filter(Usuario.username == current_user["username"]).first()
        cliente = db.query(Cliente).filter(Cliente.usuario_id == usuario.id).first()
        return [cliente] if cliente else []
    return db.query(Cliente).filter(Cliente.activo == True).offset(skip).limit(limit).all()

@router.get("/{cliente_id}", response_model=ClienteResponse)
async def obtener_cliente(cliente_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="No encontrado")
    return cliente

@router.post("/", response_model=ClienteResponse)
async def crear_cliente(data: ClienteCreate, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "vendedor"]))):
    cliente = Cliente(**data.model_dump())
    db.add(cliente)
    db.commit()
    db.refresh(cliente)
    return cliente

@router.put("/{cliente_id}", response_model=ClienteResponse)
async def actualizar_cliente(cliente_id: int, data: ClienteCreate, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "vendedor"]))):
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="No encontrado")
    for key, value in data.model_dump().items():
        setattr(cliente, key, value)
    db.commit()
    db.refresh(cliente)
    return cliente