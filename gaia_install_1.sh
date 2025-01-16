#!/bin/bash

# Проверка аргументов
if [ -z "$1" ]; then
  echo "Usage: $0 <installation_directory>"
  exit 1
fi

INSTALL_DIR=$1

# Создание директории установки, если она не существует
if [ ! -d "$INSTALL_DIR" ]; then
  echo "Создаем директорию $INSTALL_DIR..."
  mkdir -p "$INSTALL_DIR"
else
  echo "Директория $INSTALL_DIR уже существует!"
fi

# Обновляем систему
sudo apt update -y && sudo apt-get update -y
sudo apt install python3-pip -y
sudo apt install nano -y
sudo apt install screen -y
pip install requests --break-system-packages
pip install faker --break-system-packages

# Устанавливаем последнюю версию установщика Gaianet
curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash -s -- --base "$INSTALL_DIR"

source ~/.bashrc
# Завершаем установку
echo "Gaianet успешно установлен в директорию $INSTALL_DIR"

