from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List
from decimal import Decimal
from ..db.database import get_db
from ..core.security import get_current_user, require_role
from ..models.models import Pedido, DetallePedido, Producto, Inventario, EstadoPedido, RutaEntrega, Cliente, Usuario
from ..schemas.schemas import PedidoCreate, PedidoUpdate, PedidoResponse

router = APIRouter(prefix="/pedidos", tags=["pedidos"])

TRANSICIONES = {
    EstadoPedido.pendiente: [EstadoPedido.confirmado, EstadoPedido.cancelado],
    EstadoPedido.confirmado: [EstadoPedido.en_preparacion, EstadoPedido.cancelado],
    EstadoPedido.en_preparacion: [EstadoPedido.en_ruta, EstadoPedido.cancelado],
    EstadoPedido.en_ruta: [EstadoPedido.entregado, EstadoPedido.cancelado],
    EstadoPedido.entregado: [],
    EstadoPedido.cancelado: [],
}

@router.get("/", response_model=List[PedidoResponse])
async def listar_pedidos(skip: int = Query(0, ge=0), limit: int = Query(100, ge=1, le=500), db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    if current_user["role"] in ["admin", "vendedor"]:
        return db.query(Pedido).offset(skip).limit(limit).all()
    if current_user["role"] == "cliente":
        usuario = db.query(Usuario).filter(Usuario.username == current_user["username"]).first()
        cliente = db.query(Cliente).filter(Cliente.usuario_id == usuario.id).first()
        if not cliente:
            return []
        return db.query(Pedido).filter(Pedido.cliente_id == cliente.id).offset(skip).limit(limit).all()
    if current_user["role"] == "repartidor":
        return db.query(Pedido).filter(Pedido.repartidor_id != None).offset(skip).limit(limit).all()
    return []

@router.get("/{pedido_id}", response_model=PedidoResponse)
async def obtener_pedido(pedido_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    pedido = db.query(Pedido).filter(Pedido.id == pedido_id).first()
    if not pedido:
        raise HTTPException(status_code=404, detail="No encontrado")
    return pedido

@router.post("/", response_model=PedidoResponse)
async def crear_pedido(data: PedidoCreate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    for det in data.detalles:
        prod = db.query(Producto).filter(Producto.id == det.producto_id).first()
        if not prod:
            raise HTTPException(status_code=404, detail=f"Producto {det.producto_id} no encontrado")
        inv = db.query(Inventario).filter(Inventario.producto_id == det.producto_id).first()
        if not inv or inv.cantidad < det.cantidad:
            raise HTTPException(status_code=400, detail=f"Stock insuficiente para {prod.nombre}. Disponible: {inv.cantidad if inv else 0}")

    total = Decimal("0")
    for det in data.detalles:
        prod = db.query(Producto).filter(Producto.id == det.producto_id).first()
        total += prod.precio * det.cantidad

    pedido = Pedido(cliente_id=data.cliente_id, observaciones=data.observaciones, total=total)
    db.add(pedido)
    db.commit()
    db.refresh(pedido)

    for det in data.detalles:
        prod = db.query(Producto).filter(Producto.id == det.producto_id).first()
        det_pedido = DetallePedido(
            pedido_id=pedido.id, producto_id=det.producto_id,
            cantidad=det.cantidad, precio_unitario=prod.precio, subtotal=prod.precio * det.cantidad
        )
        db.add(det_pedido)
        inv = db.query(Inventario).filter(Inventario.producto_id == det.producto_id).first()
        inv.cantidad -= det.cantidad

    db.commit()
    db.refresh(pedido)
    return pedido

@router.put("/{pedido_id}", response_model=PedidoResponse)
async def actualizar_pedido(pedido_id: int, data: PedidoUpdate, db: Session = Depends(get_db), current_user: dict = Depends(require_role(["admin", "vendedor", "bodega", "repartidor"]))):
    pedido = db.query(Pedido).filter(Pedido.id == pedido_id).first()
    if not pedido:
        raise HTTPException(status_code=404, detail="No encontrado")

    if data.estado:
        nuevo = EstadoPedido(data.estado)
        permitidas = TRANSICIONES.get(pedido.estado, [])
        if nuevo not in permitidas:
            raise HTTPException(status_code=400, detail=f"No se puede pasar de '{pedido.estado.value}' a '{nuevo.value}'. Estados permitidos: {[e.value for e in permitidas]}")

        pedido.estado = nuevo

        if nuevo == EstadoPedido.en_ruta:
            existente = db.query(RutaEntrega).filter(RutaEntrega.pedido_id == pedido_id).first()
            if not existente and data.repartidor_id:
                ruta = RutaEntrega(pedido_id=pedido_id, repartidor_id=data.repartidor_id, estado="en_camino")
                db.add(ruta)
            elif not existente:
                ruta = RutaEntrega(pedido_id=pedido_id, repartidor_id=pedido.repartidor_id, estado="en_camino")
                db.add(ruta)

    if data.repartidor_id:
        pedido.repartidor_id = data.repartidor_id
    if data.observaciones:
        pedido.observaciones = data.observaciones

    db.commit()
    db.refresh(pedido)
    return pedido