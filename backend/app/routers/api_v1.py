from fastapi import APIRouter
from app.routers import auth, profile, shop, client

api_v1_router = APIRouter(prefix="/api/v1")
api_v1_router.include_router(auth.router)
api_v1_router.include_router(profile.router)
api_v1_router.include_router(shop.router)
api_v1_router.include_router(client.router)