#!/bin/bash

# Проверка наличия аргумента
if [ -z "$1" ]; then
  echo "Usage: $0 <number_of_nodes>"
  exit 1
fi

NUM_NODES=$1
BASE_PORT=8080  # Базовый порт для llamaedge_port
BASE_DIR="/root/gaianet"  # Базовая директория
CONFIG_URL="https://raw.gaianet.ai/qwen2-0.5b-instruct/config.json"

echo "Начинаем установку $NUM_NODES нод Gaianet (часть 2)..."

for ((i=1; i<=NUM_NODES; i++)); do
  NODE_DIR="${BASE_DIR}-${i}"
  NODE_PORT=$((BASE_PORT + (i - 1) * 5))
  SERVICE_NAME="gaianet${i}"
  CHAT_SCRIPT="${NODE_DIR}/random_chat_with_faker_${i}.py"
  SESSION_NAME="faker_session_${i}"

  echo "Настройка ноды $i в директории $NODE_DIR с портом $NODE_PORT..."

  # Инициализация ноды
  gaianet init --config "$CONFIG_URL" --base "$NODE_DIR"

  # Настройка конфигурации порта
  CONFIG_FILE="${NODE_DIR}/config.json"
  sed -i "s/\"llamaedge_port\": \".*\"/\"llamaedge_port\": \"$NODE_PORT\"/" "$CONFIG_FILE"

  # Запуск ноды
  gaianet start --base "$NODE_DIR"

  # Сохранение информации о ноде
  NODE_INFO_FILE="${NODE_DIR}/gaianet_info.txt"
  gaianet info --base "$NODE_DIR" > "$NODE_INFO_FILE"
  NODE_ID=$(grep 'Node ID:' "$NODE_INFO_FILE" | awk '{print $3}' | sed 's/[^a-zA-Z0-9]//g' | cut -c1-42)

  echo "Node ID: $NODE_ID сохранен для ноды $i."

  # Создание systemd-сервиса
  SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
  echo "Создаем systemd service файл для ноды $i: $SERVICE_FILE"
  cat <<EOF | sudo tee "$SERVICE_FILE"
[Unit]
Description=Gaianet Node Service $i
After=network.target

[Service]
Type=forking
RemainAfterExit=true
ExecStart=${NODE_DIR}/bin/gaianet start
ExecStop=${NODE_DIR}/bin/gaianet stop
ExecStopPost=/bin/sleep 20
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl restart "$SERVICE_NAME"
  sudo systemctl enable "$SERVICE_NAME"

  # Создание Python-скрипта общения с нодой
  echo "Создаем Python-скрипт: $CHAT_SCRIPT"
  cat <<EOF > "$CHAT_SCRIPT"
import requests
import random
import logging
import time
from faker import Faker
from datetime import datetime

node_url = "https://$NODE_ID.gaia.domains/v1/chat/completions"

faker = Faker()

headers = {
    "accept": "application/json",
    "Content-Type": "application/json"
}

logging.basicConfig(filename='chat_log_${i}.txt', level=logging.INFO, format='%(asctime)s - %(message)s')

def log_message(node, message):
    logging.info(f"{node}: {message}")

def send_message(node_url, message):
    try:
        response = requests.post(node_url, json=message, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Failed to get response from API: {e}")
        return None

def extract_reply(response):
    if response and 'choices' in response:
        return response['choices'][0]['message']['content']
    return ""

while True:
    random_question = faker.sentence(nb_words=10)
    message = {
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": random_question}
        ]
    }

    question_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    response = send_message(node_url, message)
    reply = extract_reply(response)

    reply_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    log_message("Node replied", f"Q ({question_time}): {random_question} A ({reply_time}): {reply}")

    print(f"Q ({question_time}): {random_question}\nA ({reply_time}): {reply}")

    delay = random.randint(0, 1)
    time.sleep(delay)
EOF

  # Запуск скрипта в screen-сессии
  echo "Запускаем Python-скрипт в screen-сессии: $SESSION_NAME"
  screen -dmS "$SESSION_NAME" bash -c "python3 $CHAT_SCRIPT"

  echo "Настройка ноды $i завершена!"
done

echo "Установка $NUM_NODES нод завершена успешно!"
