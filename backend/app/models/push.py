from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class PushSubscriptionKeys(BaseModel):
    p256dh: str = Field(..., min_length=10)
    auth: str = Field(..., min_length=5)


class PushSubscriptionCreate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    endpoint: str = Field(..., min_length=10, max_length=4000)
    expiration_time: Optional[int] = Field(None, alias="expirationTime")
    keys: PushSubscriptionKeys
    user_agent: Optional[str] = Field(None, max_length=500)


class PushUnsubscribeRequest(BaseModel):
    endpoint: str = Field(..., min_length=10, max_length=4000)


class PushPublicKeyOut(BaseModel):
    publicKey: str


class PushSubscriptionStatusOut(BaseModel):
    subscribed: bool
    count: int


class PushTestOut(BaseModel):
    sent: int
