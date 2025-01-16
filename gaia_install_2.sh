#!/bin/bash

# Проверка аргументов
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <node_number> <installation_directory>"
  exit 1
fi

NODE_NUMBER=$1
INSTALL_DIR=$2
PORT=$((8080 + 5 * (NODE_NUMBER - 1)))

echo "Устанавливаем ноду $NODE_NUMBER в директорию $INSTALL_DIR с портом $PORT..."

# Создание директорий
mkdir -p "$INSTALL_DIR"

# Инициализация ноды
source ~/.bashrc
gaianet init --config "https://raw.gaianet.ai/qwen2-0.5b-instruct/config.json" --base "$INSTALL_DIR"

# Настройка конфигурации
CONFIG_FILE="$INSTALL_DIR/config.json"
if [ -f "$CONFIG_FILE" ]; then
  echo "Настроим порт $PORT в конфигурации $CONFIG_FILE..."
  sed -i "s/\"llamaedge_port\":.*/\"llamaedge_port\": \"$PORT\",/" "$CONFIG_FILE"
else
  echo "Ошибка: Файл конфигурации $CONFIG_FILE не найден!"
  exit 1
fi

# Получение Node ID и Device ID
echo "Получаем Node ID и Device ID..."
gaianet info --base "$INSTALL_DIR" > "$INSTALL_DIR/gaianet_info.txt"

NODE_ID=$(grep 'Node ID:' "$INSTALL_DIR/gaianet_info.txt" | awk '{print $3}' | sed 's/[^a-zA0-9]//g' | cut -c1-42)
DEVICE_ID=$(grep 'Device ID:' "$INSTALL_DIR/gaianet_info.txt" | awk '{print $3}' | sed 's/[^a-zA-Z0-9]//g' | cut -c1-42)

echo "Node ID: $NODE_ID"
echo "Device ID: $DEVICE_ID"

# Создание systemd-сервиса для ноды
SERVICE_FILE="/etc/systemd/system/gaianet-$NODE_NUMBER.service"
echo "Создаем systemd сервис: $SERVICE_FILE..."
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Gaianet Node Service $NODE_NUMBER
After=network.target

[Service]
Type=forking
RemainAfterExit=true
ExecStart=$INSTALL_DIR/bin/gaianet start --base $INSTALL_DIR
ExecStop=$INSTALL_DIR/bin/gaianet stop --base $INSTALL_DIR
ExecStopPost=/bin/sleep 20
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

# Применяем изменения systemd
sudo systemctl daemon-reload
sudo systemctl enable gaianet-$NODE_NUMBER.service
sudo systemctl restart gaianet-$NODE_NUMBER.service

echo "Нода $NODE_NUMBER успешно установлена и запущена!"

gaianet start --base $INSTALL_DIR

# Создание скрипта random_chat_with_faker.py
CHAT_SCRIPT="$INSTALL_DIR/random_chat_with_faker.py"
echo "Создаем скрипт: $CHAT_SCRIPT"
echo "import requests
import random
import logging
import time
from faker import Faker
from datetime import datetime

node_url = \"https://$NODE_ID.gaia.domains/v1/chat/completions\"

faker = Faker()

headers = {
    \"accept\": \"application/json\",
    \"Content-Type\": \"application/json\"
}

logging.basicConfig(filename='chat_log.txt', level=logging.INFO, format='%(asctime)s - %(message)s')

def log_message(node, message):
    logging.info(f\"{node}: {message}\")

def send_message(node_url, message):
    try:
        response = requests.post(node_url, json=message, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f\"Failed to get response from API: {e}\")
        return None

def extract_reply(response):
    if response and 'choices' in response:
        return response['choices'][0]['message']['content']
    return \"\"

while True:
    random_question = faker.sentence(nb_words=10)
    message = {
        \"messages\": [
            {\"role\": \"system\", \"content\": \"You are a helpful assistant.\"},
            {\"role\": \"user\", \"content\": random_question}
        ]
    }

    question_time = datetime.now().strftime(\"%Y-%m-%d %H:%M:%S\")

    response = send_message(node_url, message)
    reply = extract_reply(response)

    reply_time = datetime.now().strftime(\"%Y-%m-%d %H:%M:%S\")

    log_message(\"Node replied\", f\"Q ({question_time}): {random_question} A ({reply_time}): {reply}\")
    
    print(f\"Q ({question_time}): {random_question}\\nA ({reply_time}): {reply}\")

    delay = random.randint(0, 1)
    time.sleep(delay)" > $CHAT_SCRIPT

# Проверяем, что файл был создан
if [ -f "$CHAT_SCRIPT" ]; then
    echo "Файл $CHAT_SCRIPT успешно создан"
else
    echo "Не удалось создать файл $CHAT_SCRIPT"
    exit 1
fi

# Запуск скрипта в screen-сессии для каждой ноды
SESSION_NAME="faker_session_$NODE_NUMBER"
echo "Запускаем скрипт в screen сессии $SESSION_NAME..."
screen -dmS "$SESSION_NAME" bash -c "python3 $CHAT_SCRIPT"

echo "Установка завершена! Скрипт общения с Gaianet AI запущен в screen сессии $SESSION_NAME."
