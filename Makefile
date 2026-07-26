.PHONY: up down logs clean ps restart setup-topics setup-bucket wait-kafka setup

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

# --- Python Environment Commands ---

setup-python:
	@echo "Setting up global Python environment with uv..."
	uv venv
	@echo "Environment created. Run 'source .venv/bin/activate' to activate."

install-deps:
	@echo "Installing Python dependencies with uv..."
	uv pip install -r services/producer/requirements.txt

# --- Infrastructure Setup Commands ---

wait-kafka:
	@echo "Waiting for Kafka to be ready..."
	@until docker exec ml_kafka /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server kafka:9092 > /dev/null 2>&1; do \
		echo "  Kafka not ready yet, retrying in 3s..."; \
		sleep 3; \
	done
	@echo "Kafka is ready."

setup-topics:
	@echo "Creating Kafka topics..."
	docker exec ml_kafka /opt/kafka/bin/kafka-topics.sh \
		--create --if-not-exists \
		--topic audio-chunks \
		--bootstrap-server kafka:9092 \
		--partitions 3 \
		--replication-factor 1
	docker exec ml_kafka /opt/kafka/bin/kafka-topics.sh \
		--create --if-not-exists \
		--topic audio-chunks-dlq \
		--bootstrap-server kafka:9092 \
		--partitions 1 \
		--replication-factor 1
	@echo "Topics created."

setup-bucket:
	@echo "Creating MinIO bucket..."
	docker exec ml_minio_init mc alias set local http://minio:9000 minioadmin minioadmin 2>/dev/null || true
	docker exec ml_minio mc mb --ignore-existing local/audio-chunks
	@echo "Bucket ready."

setup: up wait-kafka setup-topics
	@echo "Setup complete. Run 'make ps' to check container status."