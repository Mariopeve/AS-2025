# AS-2025

## Setup rápido en Ubuntu Server (Docker + Compose)

1) Clona el repo en la VM:

```bash
git clone <TU_URL_DEL_REPO>
cd AS-2025
```

2) Ejecuta el script de instalación:

```bash
chmod +x scripts/setup-docker-ubuntu.sh
./scripts/setup-docker-ubuntu.sh
```

3) Abre una nueva sesión (o cierra y reabre SSH) para aplicar el grupo `docker`.

4) Levanta un stack (cuando tengas el `compose.yml` definido):

```bash
docker compose -f stacks/development/compose.yml up -d
```
