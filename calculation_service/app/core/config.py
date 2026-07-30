import os
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "FastAPI Calculation Microservice"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    DESCRIPTION: str = (
        "High-performance standalone Calculation Service for Fare, Distance, ETA, "
        "Service Charges, Taxes, Discounts, Coupons, and Price Breakdown."
    )
    
    # Environment
    ENV: str = os.getenv("ENV", "development")
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"
    
    # Default rates & thresholds
    DEFAULT_BASE_FARE: float = 50.0
    DEFAULT_PER_KM_RATE: float = 12.0
    DEFAULT_PER_MINUTE_RATE: float = 2.0
    DEFAULT_SERVICE_CHARGE_PERCENT: float = 5.0  # 5%
    DEFAULT_TAX_PERCENT: float = 18.0            # 18% GST

    model_config = SettingsConfigDict(case_sensitive=True, env_file=".env")


settings = Settings()
