#!/bin/sh
set -eu

CERT_DIR=/etc/nginx/ssl
if [ ! -f "$CERT_DIR/selfsigned.crt" ]; then
  mkdir -p "$CERT_DIR"
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERT_DIR/selfsigned.key" \
    -out "$CERT_DIR/selfsigned.crt" \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=DuoPortfolio/CN=localhost" >/dev/null 2>&1
  echo "Certificado autofirmado generado en $CERT_DIR"
fi
