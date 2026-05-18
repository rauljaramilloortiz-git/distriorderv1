from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, extract
from datetime import datetime, timedelta
from ..db.database import get_db
from ..core.security import get_current_user, require_role
from ..models.models import Pedido, Cliente, Producto, Inventario, Factura, Pago, DetallePedido, Usuario

router = APIRouter(prefix="/reportes", tags=["reportes"])

@router.get("/ventas")
async def reporte_ventas(
    desde: str = Query(None),
    hasta: str = Query(None),
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_role(["admin", "vendedor"]))
):
    query = db.query(Pedido)
    if desde:
        query = query.filter(Pedido.created_at >= desde)
    if hasta:
        query = query.filter(Pedido.created_at <= hasta + " 23:59:59")
    pedidos = query.all()
    total = sum(float(p.total) for p in pedidos)
    return {"pedidos": len(pedidos), "total": total, "detalle": [{"id": p.id, "fecha": p.created_at, "total": float(p.total), "estado": p.estado.value} for p in pedidos]}

@router.get("/top-productos")
async def top_productos(
    limite: int = Query(10),
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_role(["admin", "vendedor"]))
):
    result = db.query(
        DetallePedido.producto_id,
        Producto.nombre,
        func.sum(DetallePedido.cantidad).label("total_vendido"),
        func.sum(DetallePedido.subtotal).label("ingresos")
    ).join(Producto).group_by(DetallePedido.producto_id, Producto.nombre).orderBy(func.sum(DetallePedido.cantidad).desc()).limit(limite).all()
    return [{"producto_id": r[0], "nombre": r[1], "total_vendido": r[2], "ingresos": float(r[3])} for r in result]

@router.get("/pedidos-por-estado")
async def pedidos_por_estado(
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_role(["admin", "vendedor"]))
):
    estados = ["pendiente", "confirmado", "en_preparacion", "en_ruta", "entregado", "cancelado"]
    result = []
    for e in estados:
        count = db.query(func.count(Pedido.id)).filter(Pedido.estado == e).scalar()
        result.append({"estado": e, "cantidad": count})
    return result

@router.get("/resumen-mensual")
async def resumen_mensual(
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_role(["admin", "vendedor"]))
):
    pedidos = db.query(Pedido).filter(extract("month", Pedido.created_at) == datetime.now().month).all()
    total = sum(float(p.total) for p in pedidos)
    return {
        "mes": datetime.now().month,
        "pedidos": len(pedidos),
        "total": total,
        "facturado": sum(float(f.total) for f in db.query(Factura).all()),
        "cobrado": sum(float(pg.monto) for pg in db.query(Pago).all())
    }

@router.get("/stock-bajo")
async def stock_bajo(
    db: Session = Depends(get_db),
    current_user: dict = Depends(require_role(["admin", "bodega"]))
):
    items = db.query(Inventario).filter(Inventario.cantidad <= Inventario.stock_minimo).all()
    return [{"producto_id": i.producto_id, "cantidad": i.cantidad, "stock_minimo": i.stock_minimo} for i in items]