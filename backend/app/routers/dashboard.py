from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..db.database import get_db
from ..core.security import get_current_user, require_role
from ..models.models import Pedido, Cliente, Producto, Usuario, Inventario
from sqlalchemy import func

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

@router.get("/stats")
async def get_stats(db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "vendedor"]))):
    total_clientes = db.query(func.count(Cliente.id)).scalar()
    total_pedidos = db.query(func.count(Pedido.id)).scalar()
    pedidos_pendientes = db.query(func.count(Pedido.id)).filter(Pedido.estado == "pendiente").scalar()
    productos_bajos = db.query(func.count(Inventario.id)).filter(Inventario.cantidad <= Inventario.stock_minimo).scalar()
    return {
        "total_clientes": total_clientes,
        "total_pedidos": total_pedidos,
        "pedidos_pendientes": pedidos_pendientes,
        "productos_bajos_stock": productos_bajos
    }

@router.get("/pedidos-mes")
async def pedidos_mes(db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "vendedor"]))):
    from sqlalchemy import extract
    pedidos = db.query(Pedido).filter(extract("month", Pedido.created_at) == extract("month", func.now())).all()
    total = sum(float(p.total) for p in pedidos)
    return {"cantidad": len(pedidos), "total": total}