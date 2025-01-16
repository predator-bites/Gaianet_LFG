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

# Устанавливаем последнюю версию установщика Gaianet
curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash -s -- --base "$INSTALL_DIR"

# Завершаем установку
echo "Gaianet успешно установлен в директорию $INSTALL_DIR"
