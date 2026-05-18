from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from ..db.database import get_db
from ..core.security import get_current_user, require_role
from ..models.models import Pago, Pedido
from ..schemas.schemas import PagoCreate, PagoResponse

router = APIRouter(prefix="/pagos", tags=["pagos"])

@router.get("/", response_model=List[PagoResponse])
async def listar_pagos(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user["role"] == "admin":
        return db.query(Pago).all()
    return db.query(Pago).join(Pedido).filter(Pedido.cliente_id == current_user.get("cliente_id", 0)).all()

@router.post("/", response_model=PagoResponse)
async def registrar_pago(data: PagoCreate, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "vendedor", "cliente"]))):
    pedido = db.query(Pedido).filter(Pedido.id == data.pedido_id).first()
    if not pedido:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    pago = Pago(**data.model_dump())
    db.add(pago)
    db.commit()
    db.refresh(pago)
    return pago