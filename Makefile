.PHONY: up down logs clean ps restart

# --- Infrastructure Commands (Docker) ---

up:
	@echo "Starting infrastructure (Postgres, MinIO, Kafka, Kafdrop)..."
	docker compose up -d

down:
	@echo "Stopping infrastructure..."
	docker compose down

logs:
	@echo "Showing infrastructure logs..."
	docker compose logs -f

ps:
	@echo "Container status..."
	docker compose ps

restart: down up

clean:
	@echo "WARNING: Stopping infrastructure and deleting ALL data (volumes)..."
	docker compose down -v

# --- Useful Commands (For future implementation) ---
# setup-topics:
# 	@echo "Creating Kafka topics..."
# 	docker exec ml_kafka kafka-topics.sh --create --topic audio-chunks --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1