from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status
from app.core.dependencies import get_db_pool, verify_api_key, get_current_user
from app.models.shop import ShopRegister, ShopOut, ShopFullProfileOut, ShopEdit
from app.models.shop_contact import ShopContactRegister, ShopContactOut
from app.models.shop_schedule import ShopRegisterSchedule, ShopScheduleOut
from app.models.shop_address import ShopAddressOut, ShopAddressRegister
from app.services import shop_service
from app.core.storage import upload_img

import asyncpg

router = APIRouter(prefix="/shop", tags=["shop"], dependencies=[Depends(verify_api_key)])

#general shop routes
@router.post('/register-shop', response_model=ShopOut, status_code=201)
async def register_shop(
    data: ShopRegister,
    current_user : dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
    ):
    
    shop = await shop_service.register_shop(
        pool,
        data,
        int(current_user['sub']),
        rol = current_user['rol'],
    )
    
    return dict(shop)

@router.put('/edit-shop/{shop_id}', response_model=ShopOut, status_code=201)
async def edit_shop(
    data: ShopEdit,
    shop_id: int,
    current_user: dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    shop = await shop_service.edit_shop(
        pool, data, int(current_user["sub"]), shop_id,current_user['rol']
    )
    
    return dict(shop)

@router.post("/upload-image")
async def submit_img(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    if current_user["rol"] != "negocio":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Solo negocios pueden subir imagenes.")
    
    if file.content_type not in ("image/jpeg", "image/png", "image/webp"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Formato de imagen no permitido.")
    
    content = await file.read()
    
    if len(content) > 5 * 1024 * 1024: #Max 5mb
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "La imagen no debe superar 5MB.")
    
    
    url = await upload_img(content, file.filename, file.content_type)
    return {"url": url}

@router.get("/my-shops", response_model=list[ShopOut])
async def get_my_shops(
    current_user : dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    shops = await shop_service.get_my_shops(pool, int(current_user["sub"]))
    return [dict(shop) for shop in shops]

#=============================GET ALL SHOP INFO================================
@router.get("/get-shop/{shop_id}", response_model=ShopFullProfileOut)
async def get_shop_by_id(
    shop_id: int,
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    return await shop_service.get_shop_full_profile(pool, shop_id)

@router.get("/get-general/{shop_id}", response_model=ShopOut)
async def get_general_info(
    shop_id: int,
    pool: asyncpg.Pool = Depends(get_db_pool),
    current_user: dict = Depends(get_current_user)
):
    shop = await shop_service.get_shop_by_id(pool, shop_id, int(current_user["sub"]))
    return dict(shop)

#Contact routes
@router.get("/get-contacts/{shop_id}", response_model=list[ShopContactOut])
async def get_contacts_by_shop(
    shop_id: int,
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    contacts = await shop_service.get_contacts_by_shop(pool, shop_id)
    return [dict(contact) for contact in contacts]

@router.post("/register-contact/{shop_id}", response_model=ShopContactOut, status_code=201)
async def add_contact(
    shop_id: int,
    data: ShopContactRegister,
    current_user : dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    contact = await shop_service.add_contact(pool, shop_id, data, int(current_user["sub"]))
    return dict(contact)

#Schedule routes
@router.get("/get-schedule/{shop_id}", response_model= list[ShopScheduleOut])
async def get_schedule_by_shop(
    shop_id: int,
    pool: asyncpg.Pool = Depends(get_db_pool),
):
    schedule = await shop_service.get_weekly_schedule(pool, shop_id)
    return [dict(sche) for sche in schedule]


@router.post("/register-schedule/{shop_id}", response_model=ShopScheduleOut, status_code=201)
async def add_schedule(
    shop_id : int,
    data : ShopRegisterSchedule,
    current_user : dict = Depends(get_current_user),
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    schedule = await shop_service.insert_schedule(
        pool, 
        shop_id, 
        data, 
        int(current_user["sub"],
    ))
    
    return dict(schedule)

#Address routes
@router.get("/get-address/{shop_id}", response_model=ShopAddressOut)
async def get_address(
    shop_id: int,
    pool: asyncpg.Pool = Depends(get_db_pool)
):
    address = await shop_service.get_address_by_shop(pool, shop_id)
    return dict(address)

@router.post("/register-address/{shop_id}", response_model=ShopAddressOut)
async def resgiter_address(
    shop_id: int,
    data: ShopAddressRegister,
    pool: asyncpg.Pool = Depends(get_db_pool),
    current_user: dict = Depends(get_current_user)
):
    address = await shop_service.insert_address(pool, shop_id, int(current_user['sub']), data)
    return dict(address)