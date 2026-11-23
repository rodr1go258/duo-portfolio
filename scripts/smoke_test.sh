#!/usr/bin/env bash
# Verificación final de HTTP (80) y HTTPS (443) en la VM desplegada.
set -euo pipefail

echo "==> HTTP :80"
curl -fsS -o /dev/null -w 'status=%{http_code}\n' http://127.0.0.1/api/health

echo "==> HTTPS :443 (certificado autofirmado)"
curl -kfsS -o /dev/null -w 'status=%{http_code}\n' https://127.0.0.1/api/health

echo "==> Frontend"
curl -fsS http://127.0.0.1/ | grep -q 'Portfolio' && echo 'frontend=ok'
