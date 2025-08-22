#!/bin/bash

# Define o diretório onde o repositório será clonado.
REPO_DIR="/home/aluno/proway-docker/proway-docker"

# URL do seu repositório Git.
REPO_URL="<https://github.com/PedroZanella/proway-docker.git>"

#Instalação do Docker e plugins necessários

echo "Verificando e instalando o Docker"

if ! command -v docker &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y \
        ca-certificates \
        docker-compose-plugin

    sudo mkdir -p /etc/apt/keyrings
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    # Adiciona o usuário atual ao grupo "docker" para não precisar de sudo.
    sudo usermod -aG docker $USER
    echo "Docker instalado com sucesso! A sessão pode precisar ser reiniciada para que as alterações no grupo 'docker' entrem em vigor."
else
    echo "Docker já está instalado."
fi

# Git Pull ou Clone do Repositório 

echo "Atualizando ou clonando o repositório Git..."
if [ -d "$REPO_DIR" ]; then
    echo "Diretório do repositório já existe. Realizando 'git pull'..."
    cd "$REPO_DIR"
    git pull
else
    echo "Diretório não encontrado. Clonando o repositório..."
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

# Deploy com Docker Compose ---

echo "Iniciando o deploy com Docker Compose..."
# 'docker compose up' com --build força a reconstrução das imagens.
# '--force-recreate' força a recriação dos containers, garantindo o deploy de novas versões.
# '-d' executa em modo detached (segundo plano).
cd "$REPO_DIR/pizzaria-app"
docker-compose up -d --build --force-recreate

# --- Parte 4: Configuração do Crontab ---

echo "Configurando o crontab para rodar o deploy a cada 5 minutos..."
CRON_JOB="*/5 * * * * cd $/home/aluno/proway-docker/proway-docker && docker compose up -d --build --force-recreate"
(crontab -l 2>/dev/null | grep -Fv "$CRON_JOB"; echo "$CRON_JOB") | crontab -

echo "Deploy finalizado. O sistema será atualizado automaticamente a cada 5 minutos."
