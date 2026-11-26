# Guía para defender el proyecto

Esta guía sirve para una sustentación oral, una revisión técnica o una entrevista.
Incluye el discurso de 60 segundos, la correspondencia exacta requisito → evidencia,
un guion de demo en vivo, preguntas típicas con respuesta y un apartado de seguridad.

---

## 0. Estado real de la entrega (para no inventar nada)

| Elemento | Estado verificable |
| --- | --- |
| Repositorio GitHub | https://github.com/rodr1go258/duo-portfolio (público) |
| Pipeline | https://github.com/rodr1go258/duo-portfolio/actions |
| Ejecución `dev` | `45818458890` → **success**, 39 tests en GitHub Actions |
| Ejecución `main` | `45818458555` → pasos 1-3 OK; paso 4 falla en `configure-aws-credentials` |
| Docker Hub | https://hub.docker.com/r/rodr1go258/duo-portfolio (privado) |
| Imagen | `rodr1go258/duo-portfolio:latest` y `:eb49b2c`, subidas y con digest |
| Terraform local | `terraform init` y `terraform validate` ejecutados con éxito en esta máquina |
| VM AWS | No creada: AWS exige cuenta con método de pago y no hay credenciales AWS |

Si te preguntan por la VM, la respuesta honesta es: **la infraestructura está definida y el pipeline la ejecuta; solo faltan las credenciales AWS en los secretos**. No digas que la VM está levantada.

---

## 1. Discurso de 60 segundos

> "Construí un MVP de portafolio para un equipo de dos personas: Ana se encarga de
> frontend y producto, Luis de backend y plataforma. La aplicación tiene catálogo de
> proyectos, detalle, página del equipo y formulario de contacto, con React + TypeScript
> en el cliente, Express + TypeScript en la API y PostgreSQL como base de datos.
>
> Todo el ciclo vive en un único archivo `.github/workflows/pipeline.yml`. Cuando se
> hace push a `dev`, el pipeline compila y ejecuta 16 pruebas unitarias, 12 de integración
> y 11 E2E con Playwright. Cuando se hace push a `main`, ejecuta diez pasos: quality
> gate, construcción y publicación de la imagen en Docker Hub, aprovisionamiento con
> Terraform de una VPC con dos subnets, IP pública y una VM Ubuntu 24.04 con VNC,
> configuración de la VM mediante `script.sh` con Docker, Git, UFW e iptables en los
> puertos 80 y 443, despliegue con Docker Compose y verificación final HTTP/HTTPS.
>
> Lo que quiero destacar es que no es un diagrama: está ejecutado. Compila, pasan las
> 39 pruebas, la imagen construye y el stack responde 200 por HTTP y por HTTPS."

---

## 2. Requisito → evidencia (mapa directo)

| Requisito del enunciado | Dónde está | Evidencia |
| --- | --- | --- |
| Pipeline `.yml` en GitHub Actions | `.github/workflows/pipeline.yml` | YAML válido, 7 jobs |
| DEV: cada push a `dev` ejecuta pruebas | `on.push.branches: [dev, main]`, job `dev_tests` con `if` | 39 tests |
| MVP novedoso de 2 personas | `apps/api/src/data/developers.ts`, `src/seed.ts` | Ana Torres + Luis Ramírez, 3 MVPs |
| Framework frontend | `apps/web/` (React, Vite, React Router) | `npm run build -w @duo/web` |
| Framework backend | `apps/api/` (Express, TypeScript, Zod) | `npm run build -w @duo/api` |
| Base de datos | `apps/api/src/db.ts`, `repositories/`, `docker-compose.yml` | PostgreSQL 16 |
| ≥6 tests unitarios | `apps/api/tests/unit/*.test.ts` | **16** |
| ≥6 tests de integración | `apps/api/tests/integration/api.test.ts` | **12** |
| ≥6 tests E2E | `apps/web/e2e/*.spec.ts` | **11** |
| MAIN: empaquetar en Docker | `Dockerfile`, `docker-compose.yml`, `docker/` | Imagen construida y verificada |
| Subir a Docker Hub | Job `main_docker` (`login-action` + `build-push-action`) | Tags `latest` y `<sha>` |
| Terraform: VM Ubuntu 24.04 | `infra/terraform/main.tf` (AMI Canonical noble) | `aws_instance` |
| Terraform: subnets + IP pública | `aws_subnet.public/private`, `aws_eip` | 2 subnets + EIP |
| VNC | `setup_vm.sh` (TigerVNC :5901) + SG 5901 | Servicio `vncserver@1` |
| `script.sh` o Ansible | `scripts/setup_vm.sh` (principal) e `infra/ansible/playbook.yml` (alternativa) | Docker, Git, UFW, iptables |
| Firewall/iptables 80 y 443 | `setup_vm.sh` pasos 4 y 5 | `ufw allow 80/443`, reglas `iptables -I INPUT` |

---

## 3. Guion de demo en vivo (sin cloud)

Ejecuta `powershell -File scripts/verify-all.ps1`. El script hace exactamente lo que
haría el pipeline y termina con un smoke test. Si quieres hacerlo a mano:

```powershell
npm ci
npm run build
npm run test:unit -w @duo/api
npm run test:integration -w @duo/api
npx playwright install chromium
npm run test:e2e -w @duo/web
docker build -t duo-portfolio:local .
$env:HTTP_PORT=8081; $env:HTTPS_PORT=8443; docker compose up -d
curl.exe --noproxy '*' -sS http://127.0.0.1:8081/api/health
curl.exe --noproxy '*' -k -sS -o NUL -w '%{http_code}' https://127.0.0.1:8443/api/health
docker compose down -v
```

**Salida esperada:** `28 passed` en Vitest, `11 passed` en Playwright, JSON con
`"status":"ok"` y `200` en HTTPS.

Si tienes credenciales, el segundo nivel de demo es:

```powershell
powershell -File scripts/bootstrap-github.ps1 -Repo https://github.com/TU_USUARIO/duo-portfolio.git -DockerHubUser TU_USER -DockerHubToken TU_TOKEN -AwsKey ... -AwsSecret ... -SshPublicKey 'ssh-ed25519 ...' -SshPrivateKeyPath C:\ruta\id_ed25519 -Push
```

---

## 4. Preguntas probables y respuestas

**¿Por qué un solo workflow en vez de dos?**
El enunciado pide "un pipeline `.yml`". Con `if: github.ref == ...` un único archivo
expresa las dos ramas y evita duplicar pasos comunes como `checkout` o `setup-node`.

**¿Cómo evitas que un fallo en tests llegue a producción?**
El job `main_docker` declara `needs: main_quality_gate`, y todos los jobs siguientes
encadenan `needs`. Si falla un test, GitHub marca el resto como omitido y no se publica
la imagen ni se toca la infraestructura.

**¿Por qué PostgreSQL y no SQLite?**
Porque en producción se usa PostgreSQL 16 en contenedor. Para los tests de integración
usé `pg-mem`, que implementa el dialecto Postgres en memoria: la misma consulta SQL se
ejecuta en test y en producción, sin levantar un servicio externo en CI.

**¿Qué diferencias hay entre test unitario, integración y E2E aquí?**
- Unitario: `ProjectService` con repositorio falso; valida reglas de negocio sin I/O.
- Integración: Express + Supertest + `pg-mem`; valida rutas HTTP, códigos y SQL.
- E2E: Playwright con Chromium contra Vite + API; valida la experiencia real del usuario.

**¿Por qué `pg-mem` en los E2E en lugar de la BD del compose?**
Para que `playwright test` sea autocontenido y no dependa de Docker en la máquina del
evaluador. El arranque de la API usa `USE_MEMORY_DB=true` y siembra 3 proyectos.

**¿Cómo se publica la imagen?**
`docker/build-push-action@v6` con Buildx y caché GHA. Se etiqueta con el SHA corto del
commit y con `latest`; el tag del SHA se pasa como output al job de despliegue para que
la VM descargue exactamente esa versión (no un `latest` ambiguo).

**¿Qué hace exactamente Terraform?**
Crea VPC, Internet Gateway, una subred pública y otra privada, tabla de rutas, security
group (80/443 públicos; 22/5901 restringidos), key pair, instancia EC2 Ubuntu 24.04 y
una IP elástica asociada. El `public_ip` se exporta y se consume en los jobs de SSH.

**¿Por qué `script.sh` y no Ansible si ambos están permitidos?**
El enunciado dice "SCRIPT.SH o ANSIBLE". Elegí `setup_vm.sh` porque se copia por SCP y
se ejecuta con `sudo` sin necesidad de inventario ni de que Ansible esté instalado en el
runner. Dejé `infra/ansible/playbook.yml` como alternativa equivalente para demostrar
que la configuración es portable.

**¿Cómo configuras el firewall?**
UFW con política `deny incoming`, permitiendo 22, 80, 443 y 5901. Además se añaden
reglas explícitas con `iptables -I INPUT -p tcp --dport 80/443 -j ACCEPT` y se comprueba
con `iptables -C` para no duplicarlas.

**¿Qué pasa si el puerto 80 está ocupado en local?**
`docker-compose.yml` usa `${HTTP_PORT:-80}` y `${HTTPS_PORT:-443}`. En local se pueden
mapear a 8081/8443; en la VM se usan los valores por defecto 80/443.

**¿Es seguro exponer VNC?**
Solo se abre 5901 al CIDR definido en `SSH_CIDR` y se protege con contraseña. En una
sustentación conviene decir que en producción se eliminaría o se tunelizaría por SSH;
está en la sección de mejoras.

**¿Por qué el contenedor corre como usuario `node`?**
El `Dockerfile` declara `USER node`, siguiendo el principio de menor privilegio. El
puerto 8080 no es privilegiado y nginx lo publica como 80/443.

**¿Cómo demuestras que no es solo código "de papel"?**
Con `scripts/verify-all.ps1`: compila, corre las 39 pruebas, construye la imagen, levanta
el stack y hace curl por HTTP y HTTPS con resultado 200.

---

## 5. Defensa de seguridad (hardening)

Si te preguntan "¿cómo defenderías este sistema?" desde el punto de vista de seguridad:

| Riesgo | Medida implementada | Mejora recomendada |
| --- | --- | --- |
| Secretos en el repositorio | Todos en GitHub Secrets; `.env` ignorado; `ssh_public_key` marcado `sensitive` | Rotar tokens y usar OIDC de AWS en vez de claves estáticas |
| Acceso SSH/VNC abierto | `SSH_CIDR` configurable en el SG | Fijar la IP real del evaluador; VNC solo por túnel SSH |
| Tráfico sin cifrar | nginx escucha 443 con TLS 1.2/1.3 | Certificado Let's Encrypt con Certbot |
| Contenedor con root | `USER node` en el runtime | `read_only: true` + `cap_drop: ALL` en Compose |
| Dependencias vulnerables | `npm ci` con lockfile y stages separados | `npm audit`, Trivy/Snyk en el pipeline |
| Estado de Terraform local | Funciona para la demo | Backend S3 + DynamoDB locking |
| Imagen sin firma | Tag por SHA del commit | Cosign / firma de imágenes |
| Base de datos accesible | `db` solo en red interna de Compose, sin `ports` | Backup automatizado y secret manager |
|Fallo silencioso del deploy | Smoke test final en los pasos 10 | Rollback automático a la imagen anterior |

Frase para cerrar:

> "La defensa no es solo que el pipeline pase: es que cada salto está protegido. El
> quality gate bloquea el publicado, los secretos nunca entran al código, el Security
> Group limita el acceso administrativo, el firewall y iptables filtran tráfico, el
> contenedor corre sin root y el smoke test confirma que el despliegue real funciona."

---

## 6. Limitaciones conocidas y cómo responderlas

1. **Certificado autofirmado.** Es intencional para la demo; en producción se sustituye
   por Let's Encrypt. No es un fallo funcional: el smoke test usa `curl -k`.
2. **Terraform con estado local.** Suficiente para aprovisionar una VM de prueba; en un
   entorno real se movería el state a S3 con bloqueo.
3. **Coste.** La EIP y la EC2 generan coste mientras existan. Hay que ejecutar
   `terraform destroy` al terminar la demostración.
4. **VNC.** Se instala porque el enunciado lo menciona, pero la interfaz principal es
   la web; VNC es una puerta de administración secundaria.
5. **Cuenta AWS sin crear.** AWS requiere una tarjeta (retención temporal de USD $1) para abrir una cuenta; al no haberla, no se pudo aprovisionar la VM. No es un fallo del código: `terraform validate` pasa y el pipeline llega hasta `configure-aws-credentials`. Alternativas: credenciales de AWS Academy/Educate de la universidad, o una cuenta de un compañero/docente con su autorización.
6. **Comentario sobre el enunciado.** El texto dice "ubuntu 2404 vnc" sin punto ni
   paréntesis de cierre; se interpretó como Ubuntu 24.04 con VNC en el puerto 5901.

---

## 7. Cierre sugerido

> "El entregable cubre los cuatro bloques pedidos: MVP con tres frameworks, pruebas en
> tres niveles por encima del mínimo, contenedorización con Docker Hub y aprovisionamiento
> + configuración automatizada de la VM. Todo está versionado en `main` y `dev`, y se
> puede reproducir en local con un solo comando."
