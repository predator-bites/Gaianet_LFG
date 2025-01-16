#!/bin/bash

# Проверка аргументов
if [ -z "$1" ]; then
  echo "Usage: $0 <number_of_nodes>"
  exit 1
fi

NUM_NODES=$1

wget https://raw.githubusercontent.com/predator-bites/Gaianet_LFG/main/gaia_install_1.sh -O gaia_install_1.sh
wget https://raw.githubusercontent.com/predator-bites/Gaianet_LFG/main/gaia_install_2.sh -O gaia_install_2.sh

# Запускаем базовую установку для каждой ноды
for ((i=1; i<=NUM_NODES; i++)); do
  INSTALL_DIR="$HOME/gaianet-$i"
  echo "Запускаем установку для ноды $i в директорию $INSTALL_DIR..."
  
  # Сначала создаем директорию установки для ноды
  mkdir -p "$INSTALL_DIR"
  
  # Затем выполняем установку с указанием директории
  bash gaia_install_1.sh "$INSTALL_DIR"
  source ~/.bashrc
  # После этого выполняем настройку ноды с теми же параметрами
  bash gaia_install_2.sh "$i" "$INSTALL_DIR"
done

echo "Установка $NUM_NODES нод завершена!"
