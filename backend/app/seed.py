from sqlalchemy.orm import Session
from app.models.models import Usuario, Categoria, Producto, Cliente, Inventario, Role, Pedido, DetallePedido, EstadoPedido
from app.core.security import get_password_hash
from decimal import Decimal
import random

def seed(db: Session):
    # Usuarios demo
    usuarios = [
        {"username": "admin", "email": "admin@dist.com", "nombre": "Administrador", "rol": Role.admin, "password": "admin123"},
        {"username": "vendedor1", "email": "vendedor@dist.com", "nombre": "Juan Pérez", "rol": Role.vendedor, "password": "vendedor123"},
        {"username": "bodega1", "email": "bodega@dist.com", "nombre": "María López", "rol": Role.bodega, "password": "bodega123"},
        {"username": "repartidor1", "email": "repartidor@dist.com", "nombre": "Carlos Díaz", "rol": Role.repartidor, "password": "repartidor123"},
        {"username": "cliente1", "email": "cliente@dist.com", "nombre": "Pedro García", "rol": Role.cliente, "password": "cliente123"},
    ]

    for u in usuarios:
        if not db.query(Usuario).filter(Usuario.username == u["username"]).first():
            user = Usuario(username=u["username"], email=u["email"], nombre=u["nombre"], rol=u["rol"], hashed_password=get_password_hash(u["password"]))
            db.add(user)

    db.commit()

    # Categorías
    categorias_data = [
        {"nombre": "Bebidas", "descripcion": "Refrescos, jugos, aguas"},
        {"nombre": "Snacks", "descripcion": "Chocolates, galletas, frituras"},
        {"nombre": "Lácteos", "descripcion": "Leche, yogur, queso"},
        {"nombre": "Cuidado Personal", "descripcion": "Jabones, champús, crema dental"},
        {"nombre": "Limpieza", "descripcion": "Detergentes, jabones, cloro"},
    ]

    cats = []
    for c in categorias_data:
        cat = db.query(Categoria).filter(Categoria.nombre == c["nombre"]).first()
        if not cat:
            cat = Categoria(**c)
            db.add(cat)
        cats.append(cat)
    db.commit()

    # Productos
    productos_data = [
        {"nombre": "Coca-Cola 600ml", "precio": "12.50", "sku": "COKE-600", "categoria_id": cats[0].id},
        {"nombre": "Pepsi 600ml", "precio": "12.00", "sku": "PEPS-600", "categoria_id": cats[0].id},
        {"nombre": "Agua Crystal 500ml", "precio": "6.00", "sku": "AGUA-500", "categoria_id": cats[0].id},
        {"nombre": "Jugo de naranja 1L", "precio": "18.00", "sku": "JUGA-1L", "categoria_id": cats[0].id},
        {"nombre": "Chocolate Hershey", "precio": "15.00", "sku": "HERS-CHOC", "categoria_id": cats[1].id},
        {"nombre": "Galletas Oreo", "precio": "14.00", "sku": "OREO-GAL", "categoria_id": cats[1].id},
        {"nombre": "Papas Lays", "precio": "16.00", "sku": "LAYS-PAP", "categoria_id": cats[1].id},
        {"nombre": "Leche Santa Clara 1L", "precio": "22.00", "sku": "SCLA-LECH", "categoria_id": cats[2].id},
        {"nombre": "Yogur Danone", "precio": "12.00", "sku": "DANONE-YOG", "categoria_id": cats[2].id},
        {"nombre": "Jabón Dove", "precio": "28.00", "sku": "DOVE-JAB", "categoria_id": cats[3].id},
        {"nombre": "Shampoo Head&Shoulders", "precio": "45.00", "sku": "HNS-SHAM", "categoria_id": cats[3].id},
        {"nombre": "Detergente Ariel 1kg", "precio": "32.00", "sku": "ARIEL-DET", "categoria_id": cats[4].id},
        {"nombre": "Cloro Zote", "precio": "18.00", "sku": "ZOTE-CLO", "categoria_id": cats[4].id},
        {"nombre": "Jabón de Tala", "precio": "14.00", "sku": "TALA-JAB", "categoria_id": cats[4].id},
    ]

    prods = []
    for p in productos_data:
        prod = db.query(Producto).filter(Producto.sku == p["sku"]).first()
        if not prod:
            prod = Producto(nombre=p["nombre"], precio=Decimal(p["precio"]), sku=p["sku"], categoria_id=p["categoria_id"])
            db.add(prod)
        prods.append(prod)
    db.commit()

    # Inventario (100 unidades cada uno)
    for prod in prods:
        inv = db.query(Inventario).filter(Inventario.producto_id == prod.id).first()
        if not inv:
            inv = Inventario(producto_id=prod.id, cantidad=100, stock_minimo=15)
            db.add(inv)
        else:
            inv.cantidad = 100
            inv.stock_minimo = 15
    db.commit()

    # Clientes
    clientes_data = [
        {"razon_social": "Supermercado El Progreso", "nit": "123456789", "telefono": "5551234001", "direccion": "Av. Principal 123"},
        {"razon_social": "Tienda Don José", "nit": "987654321", "telefono": "5551234002", "direccion": "Calle 2 #45"},
        {"razon_social": "Minimarket Santa María", "nit": "456789123", "telefono": "5551234003", "direccion": "Blvd. Norte 67"},
        {"razon_social": "Abarrotes La Esperanza", "nit": "789123456", "telefono": "5551234004", "direccion": "Av. Sur 89"},
        {"razon_social": "Farmacia San Juan", "nit": "321654987", "telefono": "5551234005", "direccion": "Calle Central 101"},
    ]

    for i, c in enumerate(clientes_data):
        cli = db.query(Cliente).filter(Cliente.nit == c["nit"]).first()
        if not cli:
            cli = Cliente(**c)
            db.add(cli)
    db.commit()

    print("Seed completado: usuarios, categorías, productos, inventario, clientes")

if __name__ == "__main__":
    from app.db.database import SessionLocal, engine, Base
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    seed(db)
    db.close()