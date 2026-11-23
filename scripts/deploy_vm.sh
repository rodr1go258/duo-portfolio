#!/usr/bin/env bash
# Despliegue de la imagen publicada en DockerHub dentro de la VM.
# Variables requeridas: DOCKERHUB_USERNAME, DOCKERHUB_TOKEN, DB_PASSWORD, IMAGE_TAG
set -euo pipefail

: "${DOCKERHUB_USERNAME:?DOCKERHUB_USERNAME es obligatorio}"
: "${DOCKERHUB_TOKEN:?DOCKERHUB_TOKEN es obligatorio}"
: "${DB_PASSWORD:?DB_PASSWORD es obligatorio}"

IMAGE_TAG="${IMAGE_TAG:-latest}"
export DOCKERHUB_USERNAME IMAGE_TAG DB_PASSWORD
export DOCKER_IMAGE="${DOCKERHUB_USERNAME}/duo-portfolio:${IMAGE_TAG}"

cd /opt/portfolio

echo "==> Autenticando en Docker Hub"
printf '%s' "${DOCKERHUB_TOKEN}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin

echo "==> Descargando imagen ${DOCKER_IMAGE}"
docker compose pull app proxy

echo "==> Levantando stack (db + app + proxy 80/443)"
docker compose up -d --remove-orphans

echo "==> Limpieza"
docker image prune -f >/dev/null

echo "==> Estado de contenedores"
docker compose ps

echo "==> Comprobación HTTP local"
curl -fsS http://127.0.0.1/api/health
