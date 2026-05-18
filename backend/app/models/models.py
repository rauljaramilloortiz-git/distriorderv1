from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Enum, Numeric
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from ..db.database import Base

class Role(str, enum.Enum):
    admin = "admin"
    vendedor = "vendedor"
    bodega = "bodega"
    repartidor = "repartidor"
    cliente = "cliente"

class EstadoPedido(str, enum.Enum):
    pendiente = "pendiente"
    confirmado = "confirmado"
    en_preparacion = "en_preparacion"
    en_ruta = "en_ruta"
    entregado = "entregado"
    cancelado = "cancelado"

class Usuario(Base):
    __tablename__ = "usuarios"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    nombre = Column(String(100), nullable=False)
    rol = Column(Enum(Role), default=Role.cliente)
    activo = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    cliente = relationship("Cliente", back_populates="usuario", uselist=False)

class Categoria(Base):
    __tablename__ = "categorias"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    descripcion = Column(String(255))
    activo = Column(Boolean, default=True)
    productos = relationship("Producto", back_populates="categoria")

class Producto(Base):
    __tablename__ = "productos"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    descripcion = Column(String(500))
    precio = Column(Numeric(10,2), nullable=False)
    sku = Column(String(50), unique=True, index=True)
    categoria_id = Column(Integer, ForeignKey("categorias.id"))
    activo = Column(Boolean, default=True)
    imagen_url = Column(String(255))
    categoria = relationship("Categoria", back_populates="productos")
    inventario = relationship("Inventario", back_populates="producto", uselist=False)
    detalles_pedido = relationship("DetallePedido", back_populates="producto")

class Cliente(Base):
    __tablename__ = "clientes"
    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), unique=True)
    razon_social = Column(String(150))
    nit = Column(String(20), unique=True)
    telefono = Column(String(20))
    direccion = Column(String(255))
    activo = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    usuario = relationship("Usuario", back_populates="cliente")
    pedidos = relationship("Pedido", back_populates="cliente")

class Inventario(Base):
    __tablename__ = "inventario"
    id = Column(Integer, primary_key=True, index=True)
    producto_id = Column(Integer, ForeignKey("productos.id"), unique=True)
    cantidad = Column(Integer, default=0)
    stock_minimo = Column(Integer, default=10)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    producto = relationship("Producto", back_populates="inventario")

class Pedido(Base):
    __tablename__ = "pedidos"
    id = Column(Integer, primary_key=True, index=True)
    cliente_id = Column(Integer, ForeignKey("clientes.id"), nullable=False)
    repartidor_id = Column(Integer, ForeignKey("usuarios.id"), nullable=True)
    estado = Column(Enum(EstadoPedido), default=EstadoPedido.pendiente)
    total = Column(Numeric(10,2), default=0)
    observaciones = Column(String(500))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    cliente = relationship("Cliente", back_populates="pedidos")
    detalles = relationship("DetallePedido", back_populates="pedido")
    pagos = relationship("Pago", back_populates="pedido")

class DetallePedido(Base):
    __tablename__ = "detalles_pedido"
    id = Column(Integer, primary_key=True, index=True)
    pedido_id = Column(Integer, ForeignKey("pedidos.id"), nullable=False)
    producto_id = Column(Integer, ForeignKey("productos.id"), nullable=False)
    cantidad = Column(Integer, nullable=False)
    precio_unitario = Column(Numeric(10,2), nullable=False)
    subtotal = Column(Numeric(10,2), nullable=False)
    pedido = relationship("Pedido", back_populates="detalles")
    producto = relationship("Producto", back_populates="detalles_pedido")

class Factura(Base):
    __tablename__ = "facturas"
    id = Column(Integer, primary_key=True, index=True)
    pedido_id = Column(Integer, ForeignKey("pedidos.id"), unique=True)
    numero = Column(String(50), unique=True, index=True)
    subtotal = Column(Numeric(10,2))
    impuesto = Column(Numeric(10,2))
    total = Column(Numeric(10,2))
    fecha_emision = Column(DateTime(timezone=True), server_default=func.now())
    pedido = relationship("Pedido")

class Pago(Base):
    __tablename__ = "pagos"
    id = Column(Integer, primary_key=True, index=True)
    pedido_id = Column(Integer, ForeignKey("pedidos.id"), nullable=False)
    monto = Column(Numeric(10,2), nullable=False)
    metodo = Column(String(50))
    referencia = Column(String(100))
    fecha_pago = Column(DateTime(timezone=True), server_default=func.now())
    pedido = relationship("Pedido", back_populates="pagos")

class RutaEntrega(Base):
    __tablename__ = "rutas_entrega"
    id = Column(Integer, primary_key=True, index=True)
    pedido_id = Column(Integer, ForeignKey("pedidos.id"), unique=True)
    repartidor_id = Column(Integer, ForeignKey("usuarios.id"))
    fecha_salida = Column(DateTime(timezone=True))
    fecha_entrega = Column(DateTime(timezone=True), nullable=True)
    estado = Column(String(50), default="programada")
    pedido = relationship("Pedido")