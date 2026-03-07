
COMPOSE_FILE	= srcs/docker-compose.yml
DATA_PATH		= /home/$(USER)/data
MARIADB_PATH	= $(DATA_PATH)/mariadb
WORDPRESS_PATH	= $(DATA_PATH)/wordpress

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
	@echo "$(GREEN)✓ Directories created$(RESET)"

build: setup
	@echo "$(BLUE)Building Docker images...$(RESET)"
	@docker compose -f $(COMPOSE_FILE) build
	@echo "$(GREEN)✓ Build complete$(RESET)"

up: setup
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

start:
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

.PHONY: all build up down stop start restart clean fclean re logs ps status help
