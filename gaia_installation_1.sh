#!/bin/bash

# Проверка наличия аргумента
if [ -z "$1" ]; then
  echo "Usage: $0 <number_of_nodes>"
  exit 1
fi

NUM_NODES=$1
BASE_PORT=8080  # Базовый порт для llamaedge_port
BASE_DIR="/root/gaianet"  # Базовая директория
INSTALL_SCRIPT="https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh"

echo "Начинаем установку $NUM_NODES нод Gaianet (часть 1)..."

# Установка необходимых пакетов
sudo apt update -y && sudo apt install -y python3-pip nano screen curl

for ((i=1; i<=NUM_NODES; i++)); do
  NODE_DIR="${BASE_DIR}-${i}"

  echo "Настройка директории для ноды $i: $NODE_DIR..."

  # Создание директории и установка ноды
  mkdir -p "$NODE_DIR"
  curl -sSfL "$INSTALL_SCRIPT" | bash -s -- --base "$NODE_DIR"
done

# Инструкция по выполнению второй части
echo "Первая часть установки завершена!"
echo "Теперь выполните команду: source ~/.bashrc"
echo "После этого запустите второй скрипт: ./install_gaianet_part2.sh $NUM_NODES"
