# Dúo Portfolio — MVP novedoso de 2 personas

Proyecto full-stack de ejemplo **real y funcional** pensado para el pipeline de GitHub Actions solicitado.
Dos desarrolladores (Ana = Frontend/Producto, Luis = Backend/Plataforma) construyen un portafolio de MVPs
con catálogo, detalle, equipo y formulario de contacto.

## Stack

| Capa | Framework / Tecnología |
| --- | --- |
| Frontend | React 18 + TypeScript + Vite + React Router |
| Backend | Node.js 20 + Express + TypeScript + Zod |
| Base de datos | PostgreSQL 16 (`pg`), `pg-mem` para tests |
| Tests | Vitest + Supertest (unit/integración), Playwright (E2E) |
| Empaquetado | Dockerfile multi-stage + Docker Compose + nginx (80/443) |
| Infraestructura | Terraform (AWS: VPC, 2 subnets, IGW, SG, EIP, EC2 Ubuntu 24.04 + VNC) |
| Configuración VM | `scripts/setup_vm.sh` (Docker, Git, UFW, iptables, VNC) o Ansible |
| CI/CD | Un único `.github/workflows/pipeline.yml` con ramas `dev` y `main` |

## Estructura

```
.github/workflows/pipeline.yml   Pipeline completo (DEV + MAIN 10 pasos)
apps/api/                        API REST (Express + TypeScript)
apps/web/                        Frontend (React + Vite) y tests E2E
docker/                          nginx.conf, Dockerfile.nginx, entrypoint TLS
infra/terraform/                 VPC, subnets, IP pública, VM Ubuntu 24.04 + VNC
infra/ansible/playbook.yml       Alternativa a script.sh
scripts/                         setup_vm.sh, deploy_vm.sh, smoke_test.sh
Dockerfile                       Imagen multi-stage (API + build del frontend)
docker-compose.yml               db + app + proxy (80/443)
```

## Pruebas automatizadas

| Tipo | Cantidad | Comando |
| --- | --- | --- |
| Unitarias | 16 | `npm run test:unit -w @duo/api` |
| Integración | 12 | `npm run test:integration -w @duo/api` |
| E2E | 11 | `npm run test:e2e -w @duo/web` |

Todas se ejecutan en **cada push a `dev`** (y en PRs hacia `dev`). El job de `main`
ejecuta además un quality gate antes de publicar.

Ejecución local:

```bash
npm ci
npm run build
npm run test -w @duo/api
npx playwright install chromium
npm run test:e2e -w @duo/web
```

Desarrollo local con API en memoria (sin PostgreSQL):

```bash
USE_MEMORY_DB=true PORT=3101 npm run dev -w @duo/api
npm run dev -w @duo/web   # http://127.0.0.1:5317
```

## Pipeline (`dev`)

`push` a `dev` → checkout, Node 20, `npm ci`, build/type-check, instalar Chromium,
16 tests unitarios, 12 de integración, 11 E2E y subida de reportes como artifact.

## Pipeline (`main`) — 10 pasos

1. Quality gate (build + tests de API).
2. Dockerfile multi-stage construido con Buildx.
3. Imagen publicada en Docker Hub (`latest` y `<sha>`).
4. Terraform `init` + `validate`.
5. Terraform `plan` (subnets, IP pública, VM Ubuntu 24.04 + VNC).
6. Terraform `apply` y salida de la IP pública.
7. Copia de `setup_vm.sh` a la VM por SCP.
8. Configuración: Docker, Git, UFW, iptables (80/443) y VNC (5901).
9. Copia del Compose + `deploy_vm.sh` y despliegue (`docker compose up -d`).
10. Smoke test HTTP `:80`, HTTPS `:443` y frontend.

## Secretos necesarios en GitHub

| Secreto | Descripción |
| --- | --- |
| `DOCKERHUB_USERNAME` | Usuario de Docker Hub |
| `DOCKERHUB_TOKEN` | Access token de Docker Hub |
| `AWS_ACCESS_KEY_ID` | Credenciales AWS para Terraform |
| `AWS_SECRET_ACCESS_KEY` | Credenciales AWS para Terraform |
| `AWS_REGION` | Región (por defecto `us-east-1`) |
| `SSH_PUBLIC_KEY` | Clave pública para la VM (`ssh-ed25519 ...`) |
| `SSH_PRIVATE_KEY` | Clave privada correspondiente (PEM con saltos de línea) |
| `SSH_USER` | Usuario SSH (por defecto `ubuntu`) |
| `SSH_CIDR` | CIDR permitido para SSH/VNC (por defecto `0.0.0.0/0`) |
| `DB_PASSWORD` | Contraseña de PostgreSQL en la VM (por defecto `portfolio`) |
| `VNC_PASSWORD` | Contraseña VNC (por defecto `duoportfolio`) |

Copia `.env.example` a `.env` y `infra/terraform/terraform.tfvars.example` a
`infra/terraform/terraform.tfvars` para trabajar en local.

## Docker local

```bash
docker compose up --build -d
curl http://localhost/api/health
curl -k https://localhost/api/health
```

El proxy nginx publica 80 y 443 (certificado autofirmado generado al arrancar).
La API sirve además el bundle de React, por lo que una sola imagen basta para todo.

## Documentación para sustentación

- [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md): diagramas Mermaid, topología AWS, decisiones técnicas y contrato de la API.
- [`docs/DEFENSA.md`](docs/DEFENSA.md): discurso de 60 segundos, mapa requisito → evidencia, demo en vivo, 12 preguntas con respuesta, hardening y limitaciones.

## Verificación y publicación asistida

```powershell
# Simula el pipeline completo en local (build + 39 tests + Docker + HTTP/HTTPS)
powershell -File scripts/verify-all.ps1

# Recupera los tokens ya guardados en esta máquina (GitHub + Docker Hub)
powershell -File scripts/extraer-credenciales-locales.ps1

# Crea el repo, configura secretos y hace push de main y dev
powershell -File scripts/bootstrap-github.ps1

# Crea el repo en Docker Hub y publica la imagen
powershell -File scripts/publicar-dockerhub.ps1
```

## Estado del despliegue externo

| Recurso | Resultado |
| --- | --- |
| Repositorio GitHub | Creado y público: https://github.com/rodr1go258/duo-portfolio |
| Secretos del repo | 9 configurados (Docker Hub, SSH, DB, VNC, región AWS) |
| Ramas `main` y `dev` | Publicadas; el push a `dev` pasó con **39 tests** |
| Repositorio Docker Hub | Creado (privado): https://hub.docker.com/r/rodr1go258/duo-portfolio — iniciar sesión como `rodr1go258` con el token de `secrets/credenciales.txt` |
| Imagen publicada | `rodr1go258/duo-portfolio:latest` y `:eb49b2c` |
| VM en AWS | Pendiente: no hay credenciales AWS en esta máquina |

Para terminar la VM, pon `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` y `AWS_REGION`
en `secrets/credenciales.txt` y ejecuta:

```powershell
powershell -File scripts/crear-vm-aws.ps1
```

Ese script registra los secretos, dispara el push a `main` y deja el `run` de GitHub Actions.

## Notas de seguridad

- El certificado TLS es autofirmado: sustituirlo por Let's Encrypt en producción.
- Restringir `SSH_CIDR` a tu IP antes de exponer SSH/VNC.
- Terraform usa estado local; configurar un backend S3 para entornos reales.
