#!/bin/bash

# Выход при любой ошибке
set -e

# Переменные
REPO_DIR="/home/berd/git_repo/linux_basic_doc1"
BACKUP_DIR="$REPO_DIR/configs"
DATE=$(date +'%Y-%m-%d_%H-%M-%S')

echo "=== Старт резервного копирования конфигураций ($DATE) ==="

# 1. Создаем папку для хранения конфигов внутри репозитория, если её нет
mkdir -p "$BACKUP_DIR"

# 2. Сбор конфигурационных файлов (Nginx, Apache2, Grafana, Prometheus)
echo "Копирование конфигурационных файлов..."

# Конфиги Nginx
if [ -d "/etc/nginx" ]; then
    echo " -> Копирование Nginx..."
    mkdir -p "$BACKUP_DIR/nginx"
    sudo cp -r /etc/nginx/* "$BACKUP_DIR/nginx/"
fi

# Конфиги Apache2
if [ -d "/etc/apache2" ]; then
    echo " -> Копирование Apache2..."
    mkdir -p "$BACKUP_DIR/apache2"
    sudo cp -r /etc/apache2/* "$BACKUP_DIR/apache2/"
fi

# Конфиги Grafana (основной ini-файл и папки с настройками/дашбордами)
if [ -d "/etc/grafana" ]; then
    echo " -> Копирование Grafana..."
    mkdir -p "$BACKUP_DIR/grafana"
    sudo cp -r /etc/grafana/* "$BACKUP_DIR/grafana/"
fi

# Конфиги Prometheus (основной yml-файл и сопутствующие правила)
if [ -d "/etc/prometheus" ]; then
    echo " -> Копирование Prometheus..."
    mkdir -p "$BACKUP_DIR/prometheus"
    sudo cp -r /etc/prometheus/* "$BACKUP_DIR/prometheus/"
fi

# 3. Смена владельца файлов на текущего пользователя, чтобы Git мог с ними работать
sudo chown -R $(whoami):$(whoami) "$BACKUP_DIR"

# 4. Переход в репозиторий и отправка в GitHub
echo "Переход в репозиторий Git..."
cd "$REPO_DIR"

echo "Добавление файлов в индекс Git..."
git add .

# Проверяем, есть ли новые изменения для коммита
if git diff-index --quiet HEAD --; then
    echo "Изменений не обнаружено. Репозиторий уже содержит актуальные конфиги."
else
    echo "Создание коммита..."
    git commit -m "Авто-бекап веб-серверов и мониторинга от $DATE"

    echo "Выгрузка на GitHub..."
    # Если имя вашей главной ветки 'master', замените 'main' на 'master'
    git push origin main
    echo "=== Успешно выгружено на GitHub! ==="
fi
