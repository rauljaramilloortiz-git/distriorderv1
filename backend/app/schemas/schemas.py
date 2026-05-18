from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from decimal import Decimal

# Auth
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class UserLogin(BaseModel):
    username: str
    password: str

# Usuario
class UsuarioBase(BaseModel):
    username: str
    email: str
    nombre: str
    rol: str

class UsuarioCreate(UsuarioBase):
    password: str

class UsuarioResponse(UsuarioBase):
    id: int
    activo: bool
    created_at: Optional[datetime] = None
    class Config:
        from_attributes = True

# Categoria
class CategoriaBase(BaseModel):
    nombre: str
    descripcion: Optional[str] = None

class CategoriaCreate(CategoriaBase):
    pass

class CategoriaResponse(CategoriaBase):
    id: int
    activo: bool
    class Config:
        from_attributes = True

# Producto
class ProductoBase(BaseModel):
    nombre: str
    descripcion: Optional[str] = None
    precio: Decimal
    sku: Optional[str] = None
    categoria_id: Optional[int] = None
    imagen_url: Optional[str] = None

class ProductoCreate(ProductoBase):
    pass

class ProductoResponse(ProductoBase):
    id: int
    activo: bool
    class Config:
        from_attributes = True

# Cliente
class ClienteBase(BaseModel):
    razon_social: str
    nit: Optional[str] = None
    telefono: Optional[str] = None
    direccion: Optional[str] = None

class ClienteCreate(ClienteBase):
    usuario_id: Optional[int] = None

class ClienteResponse(ClienteBase):
    id: int
    usuario_id: Optional[int] = None
    activo: bool
    created_at: Optional[datetime] = None
    class Config:
        from_attributes = True

# Inventario
class InventarioBase(BaseModel):
    cantidad: int
    stock_minimo: int = 10

class InventarioUpdate(BaseModel):
    cantidad: Optional[int] = None
    stock_minimo: Optional[int] = None

class InventarioResponse(InventarioBase):
    id: int
    producto_id: int
    updated_at: Optional[datetime] = None
    class Config:
        from_attributes = True

# DetallePedido
class DetallePedidoCreate(BaseModel):
    producto_id: int
    cantidad: int

class DetallePedidoResponse(BaseModel):
    id: int
    producto_id: int
    cantidad: int
    precio_unitario: Decimal
    subtotal: Decimal
    class Config:
        from_attributes = True

# Pedido
class PedidoCreate(BaseModel):
    cliente_id: int
    detalles: List[DetallePedidoCreate]
    observaciones: Optional[str] = None

class PedidoUpdate(BaseModel):
    estado: Optional[str] = None
    repartidor_id: Optional[int] = None
    observaciones: Optional[str] = None

class PedidoResponse(BaseModel):
    id: int
    cliente_id: int
    repartidor_id: Optional[int] = None
    estado: str
    total: Decimal
    observaciones: Optional[str] = None
    created_at: Optional[datetime] = None
    class Config:
        from_attributes = True

# Factura
class FacturaResponse(BaseModel):
    id: int
    pedido_id: int
    numero: str
    subtotal: Decimal
    impuesto: Decimal
    total: Decimal
    fecha_emision: Optional[datetime] = None
    class Config:
        from_attributes = True

# Pago
class PagoCreate(BaseModel):
    pedido_id: int
    monto: Decimal
    metodo: str
    referencia: Optional[str] = None

class PagoResponse(BaseModel):
    id: int
    pedido_id: int
    monto: Decimal
    metodo: str
    referencia: Optional[str] = None
    fecha_pago: Optional[datetime] = None
    class Config:
        from_attributes = True

# Ruta
class RutaCreate(BaseModel):
    pedido_id: int
    repartidor_id: int
    fecha_salida: Optional[datetime] = None

class RutaUpdate(BaseModel):
    estado: Optional[str] = None
    fecha_entrega: Optional[datetime] = None

class RutaResponse(BaseModel):
    id: int
    pedido_id: int
    repartidor_id: int
    estado: str
    fecha_salida: Optional[datetime] = None
    fecha_entrega: Optional[datetime] = None
    class Config:
        from_attributes = True