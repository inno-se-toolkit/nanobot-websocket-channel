"""Configuration for the bot."""

from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    bot_token: str = Field(..., alias="BOT_TOKEN")
    nanobot_ws_url: str = Field(..., alias="NANOBOT_WS_URL")


settings = Settings.model_validate({})
