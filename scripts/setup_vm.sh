#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Configuración de la VM Ubuntu 24.04 creada por Terraform.
# Instala Docker, Git, firewall (ufw), iptables (80/443) y VNC.
# Ejecutar con: sudo bash setup_vm.sh
# ---------------------------------------------------------------------------
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
VNC_PASSWORD="${VNC_PASSWORD:-duoportfolio}"

# En una VM recién creada, cloud-init/unattended-upgrades puede estar usando apt.
# Esperamos a que suelte los locks para no fallar con "Could not get lock".
wait_for_apt() {
  for _ in $(seq 1 36); do
    if ! pgrep -x apt >/dev/null 2>&1 \
       && ! pgrep -x apt-get >/dev/null 2>&1 \
       && ! pgrep -x dpkg >/dev/null 2>&1 \
       && ! pgrep -x unattended-upgr >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done
  echo "AVISO: apt sigue ocupado tras 3 minutos; se reintentará de todos modos" >&2
}

if command -v cloud-init >/dev/null 2>&1; then
  echo "==> [0/8] Esperando a cloud-init"
  cloud-init status --wait >/dev/null 2>&1 || true
fi
wait_for_apt

echo "==> [1/8] Actualizando sistema"
for intento in 1 2 3; do
  wait_for_apt
  if apt-get update -y; then break; fi
  echo "Reintentando apt-get update ($intento/3)..." >&2
  sleep 10
done
apt-get upgrade -y

# 2 GB de swap evitan picos de memoria durante la instalación de paquetes.
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  swapon /swapfile
  grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo "==> [2/8] Instalando paquetes base"
apt-get install -y --no-install-recommends \
  ca-certificates curl git gnupg ufw iptables openssl net-tools >/dev/null

echo "==> [3/8] Instalando Docker CE + Compose + Buildx"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg >/dev/null 2>&1
chmod a+r /etc/apt/keyrings/docker.gpg
ARCH="$(dpkg --print-architecture)"
echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y --no-install-recommends \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null
systemctl enable --now docker
usermod -aG docker ubuntu || true
docker --version
docker compose version

echo "==> [4/8] Configurando firewall (ufw)"
ufw --force reset >/dev/null
ufw default deny incoming >/dev/null
ufw default allow outgoing >/dev/null
ufw allow 22/tcp comment 'SSH' >/dev/null
ufw allow 80/tcp comment 'HTTP' >/dev/null
ufw allow 443/tcp comment 'HTTPS' >/dev/null
ufw allow 5901/tcp comment 'VNC' >/dev/null
ufw --force enable >/dev/null
ufw status verbose

echo "==> [5/8] Reglas explícitas de iptables para 80 y 443"
for PORT in 80 443; do
  if ! iptables -C INPUT -p tcp --dport "${PORT}" -j ACCEPT 2>/dev/null; then
    iptables -I INPUT -p tcp --dport "${PORT}" -j ACCEPT
  fi
done
iptables -S INPUT | head -n 20

echo "==> [6/8] Instalando escritorio ligero + VNC (puerto 5901)"
apt-get install -y --no-install-recommends xfce4 xfce4-goodies \
  tigervnc-standalone-server tigervnc-common tigervnc-tools >/dev/null
mkdir -p /home/ubuntu/.vnc
echo "${VNC_PASSWORD}" | vncpasswd -f > /home/ubuntu/.vnc/passwd
chmod 600 /home/ubuntu/.vnc/passwd
chown -R ubuntu:ubuntu /home/ubuntu/.vnc
cat > /home/ubuntu/.vnc/xstartup <<'EOT'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
EOT
chmod +x /home/ubuntu/.vnc/xstartup
chown ubuntu:ubuntu /home/ubuntu/.vnc/xstartup

cat > /etc/systemd/system/vncserver@1.service <<'EOT'
[Unit]
Description=TigerVNC server on display :1
After=syslog.target network.target

[Service]
Type=simple
User=ubuntu
PAMName=login
ExecStartPre=/bin/sh -c '/usr/bin/vncserver -kill :1 > /dev/null 2>&1 || true'
ExecStart=/usr/bin/vncserver :1 -geometry 1280x720 -depth 24 -localhost no
ExecStop=/usr/bin/vncserver -kill :1

[Install]
WantedBy=multi-user.target
EOT
systemctl daemon-reload
systemctl enable --now vncserver@1.service

echo "==> [7/8] Preparando directorio de despliegue"
mkdir -p /opt/portfolio
chown ubuntu:ubuntu /opt/portfolio

echo "VM configurada correctamente. Docker=$(docker --version) | UFW=$(ufw status | head -n 1)"
