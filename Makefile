
COMPOSE_FILE	= srcs/docker-compose.yml
DATA_PATH		= /home/$(USER)/data
MARIADB_PATH	= $(DATA_PATH)/mariadb
WORDPRESS_PATH	= $(DATA_PATH)/wordpress
SECRETS_DIR	= secrets
ENV_FILE		= srcs/.env
SECRET_FILES	= $(SECRETS_DIR)/db_password.txt \
		  $(SECRETS_DIR)/db_user_password.txt \
		  $(SECRETS_DIR)/wp_user_password.txt \
		  $(SECRETS_DIR)/wp_admin_password.txt
CONFIG_FILES	= $(ENV_FILE) $(SECRET_FILES)
ENV_REQUIRED_VARS = MARIA_DATABASE MYSQL_USER ADMIN_NAME MYSQL_HOST WP_URL WP_TITLE WP_ADMIN WP_ADMIN_EMAIL WP_USER WP_USER_EMAIL

RESET		= \033[0m
GREEN		= \033[32m
YELLOW		= \033[33m
BLUE		= \033[34m
RED			= \033[31m


all: setup up

setup:
	@echo "$(BLUE)Creating data directories...$(RESET)"
	@mkdir -p $(MARIADB_PATH)
	@mkdir -p $(WORDPRESS_PATH)
	@echo "$(BLUE)Creating config placeholders...$(RESET)"
	@mkdir -p $(SECRETS_DIR)
	@touch $(SECRET_FILES)
	@if [ ! -s $(ENV_FILE) ]; then \
		echo "$(YELLOW)Initializing $(ENV_FILE) template...$(RESET)"; \
		printf '%s\n' \
			'MARIA_DATABASE=' \
			'MYSQL_USER=' \
			'ADMIN_NAME=' \
			'MYSQL_HOST=' \
			'WP_URL=' \
			'WP_TITLE=' \
			'WP_ADMIN=' \
			'WP_ADMIN_EMAIL=' \
			'WP_USER=' \
			'WP_USER_EMAIL=' > $(ENV_FILE); \
	fi
	@echo "$(GREEN)✓ Directories created$(RESET)"

check_config: setup
	@missing=0; \
	for file in $(CONFIG_FILES); do \
		if [ ! -s "$$file" ]; then \
			echo "$(RED)✗ Missing value in $$file$(RESET)"; \
			missing=1; \
		fi; \
	done; \
	for key in $(ENV_REQUIRED_VARS); do \
		line=$$(grep -E "^$$key=" $(ENV_FILE) | head -n 1); \
		value=$${line#*=}; \
		if [ -z "$$line" ] || [ -z "$$value" ]; then \
			echo "$(RED)✗ Empty env variable: $$key in $(ENV_FILE)$(RESET)"; \
			missing=1; \
		fi; \
	done; \
	if [ $$missing -eq 1 ]; then \
		echo "$(YELLOW)Fill srcs/.env and secrets/*.txt before running docker compose.$(RESET)"; \
		exit 1; \
	fi

build: check_config
	@echo "$(BLUE)Building Docker images...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) build
	@echo "$(GREEN)✓ Build complete$(RESET)"

up: check_config
	@echo "$(BLUE)Starting containers...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)✓ Containers started$(RESET)"
	@echo "$(YELLOW)→ WordPress available at: https://inicoara.42.fr$(RESET)"

down:
	@echo "$(YELLOW)Stopping containers...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)✓ Containers stopped$(RESET)"

stop:
	@echo "$(YELLOW)Stopping containers (without removing)...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) stop
	@echo "$(GREEN)✓ Containers stopped$(RESET)"

start: check_config
	@echo "$(BLUE)Starting existing containers...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) start
	@echo "$(GREEN)✓ Containers started$(RESET)"

restart: down up

clean: down
	@echo "$(RED)Cleaning Docker resources...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) down -v --rmi all
	@echo "$(GREEN)✓ Docker resources cleaned$(RESET)"

fclean: clean
	@echo "$(RED)Removing all data...$(RESET)"
	@sudo rm -rf $(DATA_PATH)
	@docker system prune -af --volumes
	@echo "$(GREEN)✓ Full clean complete$(RESET)"

re: fclean all

logs:
	@docker compose -f $(COMPOSE_FILE) logs -f

ps:
	@docker compose -f $(COMPOSE_FILE) ps

status:
	@echo "$(BLUE)Container status:$(RESET)"
	@docker compose -f $(COMPOSE_FILE) ps
	@echo "$(BLUE)Service health:$(RESET)"
	@docker compose -f $(COMPOSE_FILE) ps --format "table {{.Service}}\t{{.Status}}"

help:
	@echo "$(BLUE)Available commands:$(RESET)"
	@echo "  make        - Setup and start containers"
	@echo "  make setup  - Create data folders and config placeholders"
	@echo "  make check_config - Validate srcs/.env and secrets are not empty"
	@echo "  make build  - Build Docker images"
	@echo "  make up     - Start containers"
	@echo "  make down   - Stop and remove containers"
	@echo "  make stop   - Stop containers"
	@echo "  make start  - Start existing containers"
	@echo "  make restart- Restart all containers"
	@echo "  make clean  - Remove containers, volumes, and images"
	@echo "  make fclean - Full clean (includes data directories)"
	@echo "  make re     - Rebuild from scratch"
	@echo "  make logs   - Follow container logs"
	@echo "  make ps     - List container status"
	@echo "  make status - Show detailed service health"

.PHONY: all setup check_config build up down stop start restart clean fclean re logs ps status help
