from pydantic import BaseModel, EmailStr, field_validator, model_validator
from typing import Optional


def _validate_password(value: str) -> str:
    if len(value) < 8:
        raise ValueError("La contraseña debe tener al menos 8 caracteres.")
    if not any(c.isupper() for c in value):
        raise ValueError("La contraseña debe incluir al menos una mayúscula.")
    if not any(c.islower() for c in value):
        raise ValueError("La contraseña debe incluir al menos una minúscula.")
    if not any(c.isdigit() for c in value):
        raise ValueError("La contraseña debe incluir al menos un número.")
    return value


class UserRegister(BaseModel):
    nombre: str
    correo: EmailStr
    password: str
    confirm_password: str
    rol: str = 'cliente'

    @field_validator("password")
    @classmethod
    def password_validation(cls, v: str) -> str:
        return _validate_password(v)

    @field_validator("rol")
    @classmethod
    def rol_validation(cls, v: str) -> str:
        rol = v.strip().lower()
        if rol not in ("cliente", "negocio"):
            raise ValueError("Rol inválido. El registro público solo permite cliente o negocio.")
        return rol


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


class ProfileUpdate(BaseModel):
    """HU_05: edición del propio perfil.

    El correo y la contraseña se consideran cambios sensibles y requieren
    `password_actual`. El nombre se puede cambiar sin ella.
    """

    nombre: Optional[str] = None
    correo: Optional[EmailStr] = None
    password_actual: Optional[str] = None
    password_nueva: Optional[str] = None
    confirm_password: Optional[str] = None

    @field_validator("nombre")
    @classmethod
    def nombre_validation(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        v = v.strip()
        if len(v) < 2:
            raise ValueError("El nombre debe tener al menos 2 caracteres.")
        return v

    @field_validator("password_nueva")
    @classmethod
    def password_nueva_validation(cls, v: Optional[str]) -> Optional[str]:
        return _validate_password(v) if v is not None else None

    @model_validator(mode="after")
    def validar_cambios(self):
        campos = [
            self.nombre is not None,
            self.correo is not None,
            self.password_nueva is not None,
        ]
        if not any(campos):
            raise ValueError("No hay cambios para guardar.")

        sensible = self.correo is not None or self.password_nueva is not None
        if sensible and not self.password_actual:
            raise ValueError("La contraseña actual es obligatoria para cambiar el correo o la contraseña.")
        if self.password_nueva is not None and self.password_nueva != self.confirm_password:
            raise ValueError("Las contraseñas nuevas no coinciden.")
        if self.confirm_password is not None and self.password_nueva is None:
            raise ValueError("La confirmación requiere una contraseña nueva.")
        return self


class PasswordResetRequest(BaseModel):
    correo: EmailStr


class PasswordResetConfirm(BaseModel):
    correo: EmailStr
    codigo: str
    nueva_password: str
    confirm_password: str

    @field_validator("codigo")
    @classmethod
    def codigo_validation(cls, v: str) -> str:
        return v.strip()

    @field_validator("nueva_password")
    @classmethod
    def nueva_password_validation(cls, v: str) -> str:
        return _validate_password(v)

    @model_validator(mode="after")
    def validar_confirmacion(self):
        if self.nueva_password != self.confirm_password:
            raise ValueError("Las contraseñas no coinciden.")
        if not self.codigo.isdigit() or len(self.codigo) != 6:
            raise ValueError("El código de verificación debe tener 6 dígitos.")
        return self


class PasswordResetRequestOut(BaseModel):
    mensaje: str
    expira_en_minutos: int
    # Solo se rellena si PASSWORD_RESET_RETURN_CODE=true (desarrollo).
    codigo: Optional[str] = None
