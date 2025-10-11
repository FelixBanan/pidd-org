#!/bin/bash

set -e # Выход при ошибке любой команды

echo "=== Настройка мониторинга ==="

# Запрос имени инстанса
while true; do
    read -p "Введите имя инстанса (сервера): " INSTANCE_NAME
    if [ -n "$INSTANCE_NAME" ]; then
        break
    else
        echo "Ошибка: имя инстанса не может быть пустым!"
    fi
done

# Запрос IP-адреса сервера Grafana
while true; do
    read -p "Введите IP-адрес сервера Grafana (remoteWrite): " GRAFANA_SERVER_IP
    if [ -n "$GRAFANA_SERVER_IP" ]; then
        break
    else
        echo "Ошибка: IP-адрес не может быть пустым!"
    fi
done

echo ""
echo "Будет использовано:"
echo "  Имя инстанса: $INSTANCE_NAME"
echo "  Сервер Grafana: $GRAFANA_SERVER_IP"
echo ""

read -p "Продолжить установку? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Установка отменена."
    exit 1
fi

echo "Создаем структуру директорий..."
mkdir -p /opt/monitoring/{cadvisor,nodeexporter,vmagent/conf.d}

echo "Устанавливаем cAdvisor..."
cd /opt/monitoring/cadvisor
wget -q https://github.com/google/cadvisor/releases/download/v0.53.0/cadvisor-v0.53.0-linux-amd64
mv cadvisor-v0.53.0-linux-amd64 cadvisor
chmod +x cadvisor

echo "Устанавливаем Node Exporter..."
cd /opt/monitoring/nodeexporter
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz
tar -xzf node_exporter-1.9.1.linux-amd64.tar.gz
cd node_exporter-1.9.1.linux-amd64
mv node_exporter /opt/monitoring/nodeexporter/
cd /opt/monitoring/nodeexporter
chmod +x node_exporter
rm -f node_exporter-1.9.1.linux-amd64.tar.gz
rm -rf node_exporter-1.9.1.linux-amd64

echo "Устанавливаем vmagent..."
cd /opt/monitoring/vmagent
wget -q https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v1.123.0/vmutils-linux-amd64-v1.123.0.tar.gz
tar -xzf vmutils-linux-amd64-v1.123.0.tar.gz
mv vmagent-prod vmagent
find . ! -name 'vmagent' -type f -delete
chmod +x vmagent

echo "Создаем конфигурационные файлы..."

cat > /opt/monitoring/vmagent/scrape.yml << EOF
scrape_config_files:
  - "/opt/monitoring/vmagent/conf.d/*.yml"

global:
  scrape_interval: 15s
EOF

cat > /opt/monitoring/vmagent/conf.d/cadvisor.yml << EOF
- job_name: integrations/cAdvisor
  scrape_interval: 15s
  static_configs:
    - targets: ['localhost:9101']
      labels:
        instance: "$INSTANCE_NAME"
EOF

cat > /opt/monitoring/vmagent/conf.d/nodeexporter.yml << EOF
- job_name: integrations/node_exporter
  scrape_interval: 15s
  static_configs:
    - targets: ['localhost:9100']
      labels:
        instance: "$INSTANCE_NAME"
EOF

echo "Создаем службы systemd..."

cat > /etc/systemd/system/cadvisor.service << EOF
[Unit]
Description=cAdvisor
Wants=network-online.target
After=network-online.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/opt/monitoring/cadvisor/cadvisor \\
        -listen_ip=127.0.0.1 \\
        -logtostderr \\
        -port=9101 \\
        -docker_only=true
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/nodeexporter.service << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/opt/monitoring/nodeexporter/node_exporter --web.listen-address=127.0.0.1:9100
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/vmagent.service << EOF
[Unit]
Description=VictoriaMetrics Agent
Wants=network-online.target
After=network-online.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/opt/monitoring/vmagent/vmagent \\
      -httpListenAddr=127.0.0.1:8429 \\
      -promscrape.config=/opt/monitoring/vmagent/scrape.yml \\
      -promscrape.configCheckInterval=60s \\
      -remoteWrite.url=http://$GRAFANA_SERVER_IP:8428/api/v1/write
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Запускаем службы..."
systemctl daemon-reload
systemctl enable cadvisor nodeexporter vmagent
systemctl start cadvisor nodeexporter vmagent

echo "Даем службам время на запуск..."
sleep 5

echo "Проверяем статус служб..."
echo -e "\n=== cAdvisor Status ==="
systemctl status cadvisor --no-pager || echo "Проверка статуса cAdvisor завершилась с ошибкой"

echo -e "\n=== Node Exporter Status ==="
systemctl status nodeexporter --no-pager || echo "Проверка статуса Node Exporter завершилась с ошибкой"

echo -e "\n=== vmagent Status ==="
systemctl status vmagent --no-pager || echo "Проверка статуса vmagent завершилась с ошибкой"

echo -e "\n=== Проверка прослушиваемых портов ==="
echo "Порты, которые должны слушаться:"
echo "  cAdvisor: 9101"
echo "  Node Exporter: 9100" 
echo "  vmagent: 8429"
echo ""
netstat -tlnp | grep -E ":(9100|9101|8429)" || echo "Не все порты прослушиваются"

echo -e "\nУстановка завершена!"
echo "Имя инстанса: $INSTANCE_NAME"
echo "Сервер Grafana: $GRAFANA_SERVER_IP"
echo ""
echo "Для просмотра логов используйте:"
echo "  journalctl -u cadvisor -f"
echo "  journalctl -u nodeexporter -f" 
echo "  journalctl -u vmagent -f"
