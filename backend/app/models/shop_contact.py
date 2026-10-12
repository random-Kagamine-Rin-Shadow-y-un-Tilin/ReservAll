from pydantic import BaseModel
from enum import Enum

class SocialMedia(str, Enum):
    facebook = "facebook"
    instagram = 'instagram'
    whatsapp = 'whatsapp'
    telefono = 'telefono'
    tiktok = 'tiktok'
    x = 'x'
    sitio_web = 'sitio_web'

class ShopContactRegister(BaseModel):
    nombre_red : SocialMedia
    url : str

class ShopContactOut(BaseModel):
    id_social: int
    nombre_red: str
    url: str