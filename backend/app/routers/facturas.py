from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from decimal import Decimal
from ..db.database import get_db
from ..core.security import get_current_user, require_role
from ..models.models import Factura, Pedido
from ..schemas.schemas import FacturaResponse

router = APIRouter(prefix="/facturas", tags=["facturas"])

@router.get("/", response_model=List[FacturaResponse])
async def listar_facturas(db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "vendedor"]))):
    return db.query(Factura).all()

@router.post("/{pedido_id}", response_model=FacturaResponse)
async def crear_factura(pedido_id: int, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "vendedor"]))):
    pedido = db.query(Pedido).filter(Pedido.id == pedido_id).first()
    if not pedido:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    if db.query(Factura).filter(Factura.pedido_id == pedido_id).first():
        raise HTTPException(status_code=400, detail="Factura ya existe para este pedido")
    factura = Factura(
        pedido_id=pedido_id, numero=f"FCT-{pedido_id:06d}",
        subtotal=pedido.total * Decimal("0.81"),
        impuesto=pedido.total * Decimal("0.19"),
        total=pedido.total
    )
    db.add(factura)
    db.commit()
    db.refresh(factura)
    return factura