from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Kafka
    kafka_bootstrap_servers: str
    kafka_topic: str = "audio-chunks"

    # MinIO

    # Postgres

    # Chunking
    chunk_duration_s: float = 5.0

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"