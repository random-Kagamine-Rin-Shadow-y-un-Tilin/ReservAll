from pydantic import BaseModel, EmailStr, field_validator

class UserRegister(BaseModel):
    nombre: str
    correo: EmailStr
    password: str
    confirm_password: str
    rol: str = 'cliente'
    
    @field_validator("password")
    @classmethod
    def password_validation(cls, v:str) -> str:
        if len(v) < 8:
            raise ValueError("La contraseña debe tener al menos 8 caracteres.")
        if not any(c.isupper() for c in v):
            raise ValueError("La contraseña debe incluir al menos una mayúscula.")
        if not any(c.islower() for c in v):
            raise ValueError("La contraseña debe incluir al menos una minúscula.")
        if not any(c.isdigit() for c in v):
            raise ValueError("La contraseña debe incluir al menos un número.")
        return v

class UserLogin(BaseModel):
    correo: EmailStr
    password: str
    
class UserOut(BaseModel):
    id: int
    nombre: str
    correo: str
    rol: str

class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut