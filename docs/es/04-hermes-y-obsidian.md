# 4. Conectar Hermes al vault

🌐 [English](../en/04-hermes-and-obsidian.md) · **Español**

[← Anterior: Sincronización en el LXC](03-sincronizacion-lxc.md) · [Índice](../../README.es.md) · [Siguiente: Tailscale en el LXC →](05-tailscale.md)

En esta parte se instala Hermes Agent, se conecta a OpenRouter y se le indica dónde está el vault y cómo sincronizarlo. Todo como usuario `hermes` (nunca como `root`).

## 4.1 Instalar Hermes

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

El instalador prepara Python y las dependencias sin necesitar sudo. Al terminar, cierra y vuelve a abrir la sesión (`exit` y `su - hermes`) para que reconozca el comando:

```bash
hermes --version
```

## 4.2 Configurar OpenRouter

```bash
hermes setup
```

1. Elige **OpenRouter** como proveedor.
2. Pega tu API key de OpenRouter.
3. Elige un modelo con **al menos 64K tokens de contexto**: Hermes rechaza modelos con ventanas más pequeñas.

Los modelos gratuitos de OpenRouter (los que terminan en `:free`) tienen límites de uso estrictos. Para uso diario, un pequeño saldo con un modelo económico funciona mucho mejor. Para cambiar el modelo más adelante: `hermes model`.

## 4.3 Indicar la ruta del vault

La skill de Obsidian viene incluida en Hermes. Encuentra el vault mediante la variable `OBSIDIAN_VAULT_PATH`; si no está definida, busca en `~/Documents/Obsidian Vault`, que aquí no existe.

```bash
nano ~/.hermes/.env
```

Este archivo ya contiene la API key de OpenRouter: **no borres nada**. Añade al final:

```
OBSIDIAN_VAULT_PATH=/home/hermes/vault/<nombre-vault>
```

Guarda (**Ctrl+O**, **Enter**) y sal (**Ctrl+X**). Si Hermes o su gateway ya estaban en marcha, reinícialos para que lean el cambio.

## 4.4 Enseñarle a usar el script

Abre Hermes:

```bash
hermes
```

Y pídele que lo guarde en su memoria permanente:

> Guarda esto en tu memoria: Mi vault de Obsidian está en /home/hermes/vault/&lt;nombre-vault&gt; y es parte de un repositorio Git sincronizado con GitHub. Antes de leer o buscar notas, ejecuta ~/sync-vault.sh para tener la versión más reciente. Después de crear o editar notas, ejecuta ~/sync-vault.sh para subir los cambios. Cuando crees notas nuevas por tu cuenta, guárdalas en la carpeta Hermes/ dentro del vault, salvo que yo te indique otra ubicación.

La ruta se repite en la memoria porque la skill no confirma qué vault usa al cargar. Con la variable y la memoria queda cubierto por ambos lados.

La carpeta `Hermes/` evita conflictos: Hermes escribe en su propia zona y solo toca tus notas cuando se lo pides. El timer del paso anterior garantiza la sincronización aunque Hermes olvide ejecutar el script.

## 4.5 Probar

> Lista las notas de mi vault de Obsidian y resúmeme de qué trata la nota prueba-hermes.

> Crea una nota en mi vault llamada "Primera nota de Hermes" con un resumen de lo que puedes hacer con mis notas, y sincroniza los cambios.

Unos minutos después, la carpeta `Hermes` con esa nota aparece en Obsidian (o al instante con **Ctrl+P → Git: Pull**).

## 4.6 Gateway y Telegram

El gateway es el proceso que mantiene a Hermes disponible fuera de la terminal: atiende mensajería (como Telegram) y, más adelante, el API que usa la interfaz web.

1. En Telegram, habla con **@BotFather**, crea un bot con `/newbot` y copia el token.
2. Configura el gateway y conecta Telegram:

```bash
hermes gateway setup
```

3. Instálalo como servicio para que arranque solo:

```bash
hermes gateway install
```

Con esto, Hermes responde por Telegram aunque no haya ninguna terminal abierta, y puede enviar ahí los resultados de sus tareas programadas con notificación en el móvil. Telegram, la terminal y la interfaz web comparten la misma memoria y las mismas skills.

## Comprobación

- Hermes lista tus notas y crea la nota de prueba.
- La nota aparece en Obsidian sin intervención manual.
- El bot de Telegram responde.

[← Anterior: Sincronización en el LXC](03-sincronizacion-lxc.md) · [Índice](../../README.es.md) · [Siguiente: Tailscale en el LXC →](05-tailscale.md)
