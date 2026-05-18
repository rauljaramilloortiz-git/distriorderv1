from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from ..db.database import get_db
from ..core.security import verify_password, get_password_hash, create_access_token, get_current_user
from ..models.models import Usuario, Role
from ..schemas.schemas import Token, UserLogin, UsuarioCreate, UsuarioResponse

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(Usuario).filter(Usuario.username == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
    if not user.activo:
        raise HTTPException(status_code=403, detail="Usuario inactivo")
    access_token = create_access_token(data={"sub": user.username, "role": user.rol.value})
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/register", response_model=UsuarioResponse)
async def register(data: UsuarioCreate, db: Session = Depends(get_db)):
    if db.query(Usuario).filter(Usuario.username == data.username).first():
        raise HTTPException(status_code=400, detail="Usuario ya existe")
    if db.query(Usuario).filter(Usuario.email == data.email).first():
        raise HTTPException(status_code=400, detail="Email ya existe")
    user = Usuario(
        username=data.username,
        email=data.email,
        nombre=data.nombre,
        rol=Role(data.rol),
        hashed_password=get_password_hash(data.password)
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.get("/me", response_model=UsuarioResponse)
async def get_me(current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    user = db.query(Usuario).filter(Usuario.username == current_user["username"]).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return user