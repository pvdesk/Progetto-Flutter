# ====== Makefile (Progetto Flutter) ======
COMPOSE = docker compose

.PHONY: up flutter php db mongo ps logs sh-flutter sh-php run-web build-web down downv help

up:           ## Avvia flutter + db + pma + mongo + me
	$(COMPOSE) up -d --build flutter db phpmyadmin mongo mongo-express

flutter:      ## Solo Flutter
	$(COMPOSE) up -d flutter

php:          ## Solo backend PHP (se presente)
	$(COMPOSE) up -d php

db:           ## MySQL + phpMyAdmin
	$(COMPOSE) up -d db phpmyadmin

mongo:        ## Mongo + Mongo Express
	$(COMPOSE) up -d mongo mongo-express

ps:           ## Stato servizi
	$(COMPOSE) ps

logs:         ## Log di tutti
	$(COMPOSE) logs -f

sh-flutter:   ## Shell nel container flutter
	$(COMPOSE) exec flutter bash

sh-php:       ## Shell nel container php (se presente)
	$(COMPOSE) exec php bash

run-web:      ## Avvia Flutter Web su 8080 (dentro il container flutter)
	$(COMPOSE) exec flutter flutter run -d chrome --web-hostname 0.0.0.0 --web-port 8080

build-web:    ## Build Flutter Web
	$(COMPOSE) exec flutter flutter build web

down:         ## Ferma e rimuove i container
	$(COMPOSE) down

downv:        ## Ferma e rimuove ANCHE i volumi (ATTENZIONE)
	$(COMPOSE) down -v


help:         ## Elenco comandi
	@grep -E '^[a-zA-Z0-9_-]+:.*?##' Makefile | sed 's/:.*##/: /'

# === Comandi Git ===
git-status:   ## Mostra lo stato git
	git status

git-pull:     ## Esegue git pull
	git pull

git-push:     ## Esegue git push
	git push

git-commit:   ## Esegue git commit con messaggio (usa: make git-commit MSG="messaggio")
	@test -n "$(MSG)" || (echo "Uso: make git-commit MSG='messaggio'"; exit 2)
	git add .
	git commit -m "$(MSG)"
