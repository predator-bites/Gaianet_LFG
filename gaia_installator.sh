#!/bin/bash

# Проверка наличия аргумента
if [ -z "$1" ]; then
  echo "Usage: $0 <number_of_nodes>"
  exit 1
fi

NUM_NODES=$1

# Проверяем, что оба необходимых скрипта существуют
PART1="install_gaianet_part1.sh"
PART2="install_gaianet_part2.sh"

if [ ! -f "$PART1" ]; then
  echo "Ошибка: $PART1 не найден. Убедитесь, что файл существует."
  exit 1
fi

if [ ! -f "$PART2" ]; then
  echo "Ошибка: $PART2 не найден. Убедитесь, что файл существует."
  exit 1
fi

# Выполнение первой части
echo "Запускаем первую часть установки..."
bash "$PART1" "$NUM_NODES"

# Применяем изменения в bashrc
echo "Применяем изменения из ~/.bashrc..."
source ~/.bashrc

# Выполнение второй части
echo "Запускаем вторую часть установки..."
bash "$PART2" "$NUM_NODES"

echo "Установка всех $NUM_NODES нод завершена!"
