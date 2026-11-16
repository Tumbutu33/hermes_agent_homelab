# 7. Solución de problemas

🌐 [English](../en/07-troubleshooting.md) · **Español**

[← Anterior: Hermes Workspace](06-hermes-workspace.md) · [Índice](../../README.es.md) · [Siguiente: Decisiones de diseño →](08-decisiones-de-diseno.md)

Esta guía recoge **todos los errores que aparecieron durante la instalación real**, en el orden en que surgieron, con el mensaje exacto, la causa y la solución. Al final hay una sección con otros errores posibles que no llegaron a ocurrir pero conviene conocer.

## Resumen

| # | Fase | Síntoma |
| --- | --- | --- |
| [E1](#e1-hermes-is-not-in-the-sudoers-file) | Contenedor | `hermes is not in the sudoers file` |
| [E2](#e2-no-recuerdo-la-contraseña-de-hermes) | Contenedor | Contraseña de `hermes` olvidada |
| [E3](#e3-un-comando-no-muestra-nada) | Contenedor | `chmod` y otros comandos no muestran nada |
| [E4](#e4-ctrlw-cierra-la-consola-de-proxmox) | Contenedor | Ctrl+W en nano cierra la consola |
| [E5](#e5-el-bloque-con-eof-no-funciona) | Contenedor | Bloques con `<< 'EOF'` no funcionan |
| [E6](#e6-key-is-invalid-al-pegar-la-llave-en-github) | Deploy key | `Key is invalid. You must supply a key in OpenSSH public key format` |
| [E7](#e7-aparece-sha256-en-lugar-de-la-llave) | Deploy key | Aparece `SHA256:...` en lugar de la llave |
| [E8](#e8-the-authenticity-of-host-githubcom-cant-be-established) | SSH | Pregunta de autenticidad de `github.com` |
| [E9](#e9-repository-not-found-al-clonar-en-el-contenedor) | Clon | `ERROR: Repository not found` en el contenedor |
| [E10](#e10-nombre-del-repositorio-o-nombre-del-vault) | Clon | Duda entre nombre del repo y nombre del vault |
| [E11](#e11-las-notas-no-aparecen-en-github) | PC | Las notas no aparecen en GitHub |
| [E12](#e12-select-or-create-a-new-remote) | PC | Selector de remoto en Obsidian |
| [E13](#e13-no-changes-to-commit) | PC | `No changes to commit` |
| [E14](#e14-repository-not-found-desde-obsidian) | PC | `Repository not found` con la dirección de ejemplo |
| [E15](#e15-push-rechazado-por-historiales-distintos) | PC | Push rechazado por el README de GitHub |
| [E16](#e16-ls-vault-no-muestra-nada) | Clon | `ls ~/vault` vacío |
| [E17](#e17-el-repo-contiene-una-subcarpeta-y-desktopini) | Clon | Aparecen una subcarpeta y `desktop.ini` |
| [E18](#e18-el-gitignore-no-se-aplica-dentro-del-vault) | Clon | El `.gitignore` no se aplica al vault |
| [E19](#e19-api_server_host0000-y-clave-compartida) | API | Configuración heredada y clave expuesta |
| [E20](#e20-sudo-tailscale-command-not-found) | Tailscale | `sudo: tailscale: command not found` |
| [E21](#e21-usar-tailscale-desde-otra-máquina) | Tailscale | Ejecutar `tailscale serve` en otra máquina |
| [E22](#e22-workspace-no-pide-iniciar-sesión) | Workspace | La interfaz no pide contraseña |
| [E23](#e23-authentication-error-en-el-chat) | Workspace | `Authentication error — check your API key in Settings` |
| [E24](#e24-aviso-de-actualizaciones-en-workspace) | Workspace | Aviso de actualizaciones disponibles |

---

## Errores encontrados durante la instalación

### E1. hermes is not in the sudoers file

```
[sudo] password for hermes:
hermes is not in the sudoers file.
This incident has been reported to the administrator.
```

**Cuándo:** al ejecutar `sudo loginctl enable-linger hermes`.

**Causa:** el usuario `hermes` no pertenecía al grupo `sudo`. El aviso "This incident has been reported" solo queda en un registro del propio contenedor.

**Solución:** como `root` (escribe `exit` para volver a él):

```bash
loginctl enable-linger hermes
```

```bash
usermod -aG sudo hermes
```

Vuelve con `su - hermes` y comprueba con `groups` que aparece `sudo`.

### E2. No recuerdo la contraseña de hermes

**Solución:** como `root` se cambia sin necesitar la anterior:

```bash
passwd hermes
```

Si tampoco se conoce la de `root`: Proxmox → nodo → **Shell** → `pct enter <ID>`, que entra como `root` sin contraseña.

### E3. Un comando no muestra nada

**Cuándo:** después de `chmod +x ~/sync-vault.sh`.

**Causa:** no es un error. En Linux, la mayoría de comandos solo escriben algo si fallan.

**Comprobación:** `ls -l ~/sync-vault.sh` debe empezar por `-rwxr-xr-x`.

### E4. Ctrl+W cierra la consola de Proxmox

**Cuándo:** al intentar buscar texto dentro de nano en la consola web.

**Causa:** Ctrl+W es el atajo del navegador para cerrar la pestaña, y el navegador lo intercepta antes que nano.

**Solución:**

- En nano, buscar con **F6** en lugar de Ctrl+W.
- Mejor aún, editar sin abrir nano cuando sea posible, por ejemplo con `sed`.
- Si nano se cerró de golpe, puede haber dejado una copia de emergencia (`.env.save`): bórrala con `rm -f .env.save`.

Ctrl+O (guardar) y Ctrl+X (salir) sí funcionan en el navegador.

### E5. El bloque con EOF no funciona

**Cuándo:** al pegar este bloque para crear `~/.ssh/config`:

```bash
cat >> ~/.ssh/config << 'EOF'
Host github-vault
  ...
EOF
```

**Causa:** se pegó todo en una sola línea. Ese bloque necesita que `EOF` esté solo en su propia línea, y el archivo de configuración de SSH necesita una opción por línea.

**Solución:** crear el archivo con `nano` y pegar el contenido respetando los saltos de línea. Si el archivo quedó mal, revisarlo con `cat ~/.ssh/config` y reescribirlo.

### E6. Key is invalid al pegar la llave en GitHub

```
Key is invalid. You must supply a key in OpenSSH public key format
```

**Causa:** la llave se copió desde la consola **noVNC** de Proxmox, que maneja mal el portapapeles: el texto queda cortado, partido en varias líneas o con caracteres extraños.

**Solución:**

1. Abrir la consola **xterm.js** (desplegable junto a **Console**).
2. Ejecutar `cat ~/.ssh/vault_key.pub` y copiar la línea completa, desde `ssh-ed25519` hasta `hermes-lxc`.
3. Si hay dudas, pegarla primero en un editor de texto y comprobar que es una sola línea.

Si alguna vez se pega la llave **privada** en algún sitio, hay que generar un par nuevo.

### E7. Aparece SHA256 en lugar de la llave

```
SHA256:xxxxxxxxxxxxxxxx...
```

**Cuándo:** al ejecutar `ssh-keygen -l -f ~/.ssh/vault_key.pub`.

**Causa:** eso es la **huella** de la llave, un resumen para compararla. Confirma que la llave es válida, pero no sirve para pegarla en GitHub.

**Solución:** usar `cat ~/.ssh/vault_key.pub`. Después de añadir la llave, GitHub muestra esa misma huella en la lista de Deploy keys, lo que confirma que es la correcta.

### E8. The authenticity of host github.com can't be established

```
Cloning into '/home/hermes/vault'...
The authenticity of host 'github.com (...)' can't be established.
ED25519 key fingerprint is SHA256:....
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

**Causa:** es la primera conexión del contenedor con GitHub. SSH pide confirmar que el servidor es el real.

**Solución:** comparar la huella con la huella ED25519 oficial que publica GitHub y, si coincide, escribir `yes`. Queda guardada en `~/.ssh/known_hosts` y no vuelve a preguntar. Es importante hacerlo una vez a mano: el script automático no puede responder a esa pregunta.

Si el comando de clone se pegó junto con otros, los siguientes no se ejecutaron mientras la terminal esperaba la respuesta: hay que repetirlos.

### E9. Repository not found al clonar en el contenedor

```
Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
ERROR: Repository not found.
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
```

**Causa:** el comando de clone tenía los nombres de ejemplo (`TU-USUARIO/obsidian-vault`) en lugar del usuario y repositorio reales. La primera línea indica que la conexión con GitHub sí funcionaba.

**Solución:** averiguar los nombres exactos con la propia llave:

```bash
ssh -T github-vault
```

```
Hi <usuario-github>/<repo-vault>! You've successfully authenticated, but GitHub does not provide shell access.
```

Usar exactamente ese usuario y ese repositorio, respetando mayúsculas:

```bash
git clone github-vault:<usuario-github>/<repo-vault>.git ~/vault
```

Otra forma segura: en GitHub, botón **Code → SSH**, copiar la dirección y cambiar `git@github.com:` por `github-vault:`.

### E10. Nombre del repositorio o nombre del vault

**Duda:** ¿en el clone va el nombre que se le dio al vault en Obsidian?

**Respuesta:** no. Son tres nombres independientes:

| Nombre | Qué es | Dónde se usa |
| --- | --- | --- |
| `<repo-vault>` | Repositorio en GitHub | Comandos de Git |
| `<nombre-vault>` | Carpeta del vault en Obsidian | Ruta que usa Hermes |
| `~/vault` | Carpeta de la copia en el contenedor | Script de sincronización |

Si se cambia el nombre de la carpeta en el contenedor, conviene evitar espacios: complican los comandos y los scripts.

### E11. Las notas no aparecen en GitHub

**Duda:** ¿es por el intervalo de 5 minutos?

**Causa:** no. Si después de forzar **Git: Commit-and-sync** siguen sin aparecer, la carpeta no estaba vinculada al repositorio, o los commits no se habían enviado (commit y push son pasos distintos). En este caso, la causa final fue la dirección del remoto ([E14](#e14-repository-not-found-desde-obsidian)).

**Diagnóstico:** observar la notificación de Obsidian al hacer **Git: Commit-and-sync**, o ejecutar `git status` en Git Bash:

| Mensaje | Significado |
| --- | --- |
| `Can't find a valid git repository` | La carpeta no es un repositorio: seguir la [parte 2](02-vault-y-github.md#26-convertir-la-carpeta-en-repositorio) |
| `Your branch is ahead of 'origin/main'` | Hay commits sin subir: `git push -u origin main` |
| `No changes to commit` | Ver [E13](#e13-no-changes-to-commit) |

### E12. Select or create a new remote

```
Select or create a new remote by typing its name and selecting it
  ...
  origin
```

**Cuándo:** la primera vez que se sincroniza desde Obsidian.

**Causa:** no es un error. La rama local todavía no tiene un destino configurado.

**Solución:** elegir `origin`. Si después pregunta la rama, elegir o escribir `main`.

### E13. No changes to commit

**Cuándo:** al sincronizar después de elegir `origin`.

**Causa:** no es un error. Las notas ya están guardadas en un commit local; falta enviarlas (push).

**Solución:** **Ctrl+P → Git: Push**, o en Git Bash `git push -u origin main`.

### E14. Repository not found desde Obsidian

```
remote: Repository not found.
fatal: repository 'https://github.com/TU-USUARIO/obsidian-vault.git/' not found
```

**Cuándo:** al hacer push desde Obsidian, después de iniciar sesión en GitHub.

**Causa:** el remoto `origin` del PC se había creado con la dirección de ejemplo de la guía. El inicio de sesión funcionaba; la dirección no.

**Solución:** en Git Bash, dentro de la raíz del repositorio:

```bash
git remote set-url origin https://github.com/<usuario-github>/<repo-vault>.git
```

```bash
git remote -v
```

Después, unir con el README de GitHub y subir ([E15](#e15-push-rechazado-por-historiales-distintos)).

### E15. Push rechazado por historiales distintos

Mensajes típicos si se intenta subir sin unir antes los historiales:

```
! [rejected]        main -> main (fetch first)
fatal: refusing to merge unrelated histories
```

**Causa:** el repositorio de GitHub se creó con un README y la carpeta local tenía las notas. Son dos historiales que nunca se habían unido.

**Solución:**

```bash
git pull origin main --allow-unrelated-histories --no-rebase
```

```bash
git push -u origin main
```

Si se abre un editor pidiendo un mensaje de merge, escribir `:wq` y Enter. En esta instalación, estos dos comandos se ejecutaron directamente después de corregir el remoto ([E14](#e14-repository-not-found-desde-obsidian)), así que el rechazo se evitó y el repositorio quedó actualizado.

### E16. ls ~/vault no muestra nada

**Causa:** la carpeta `~/vault` existía pero estaba vacía, creada por el intento de clone fallido ([E9](#e9-repository-not-found-al-clonar-en-el-contenedor)).

**Diagnóstico:**

```bash
ls -la ~/vault
```

| Resultado | Solución |
| --- | --- |
| Solo `.` y `..` | `cd`, `rm -rf ~/vault` y repetir el clone |
| Aparece `.git` | `cd ~/vault` y `git pull origin main` |

### E17. El repo contiene una subcarpeta y desktop.ini

```
<nombre-vault>  desktop.ini
```

**Cuándo:** al listar `~/vault` después del clone.

**Causa:** el repositorio se inicializó en la carpeta que **contiene** el vault, no dentro del vault. `desktop.ini` es un archivo de sistema que Windows crea en algunas carpetas.

**Solución:**

- No hace falta reestructurar nada: la ruta del vault en el contenedor pasa a ser `~/vault/<nombre-vault>`, y esa es la que se le da a Hermes. El script de sincronización trabaja sobre todo el repositorio, así que no cambia.
- Quitar `desktop.ini` del repositorio sin borrarlo del PC, desde Git Bash en la raíz:

```bash
echo "desktop.ini" >> .gitignore
```

```bash
git rm --cached desktop.ini
```

```bash
git commit -m "Ignorar desktop.ini"
```

```bash
git push
```

Si no se sabe cuál es la raíz, `git rev-parse --show-toplevel` la muestra. Hay que recordar que todo lo que se guarde en esa carpeta raíz también se sube a GitHub.

### E18. El .gitignore no se aplica dentro del vault

**Cuándo:** detectado al revisar la configuración, después de [E17](#e17-el-repo-contiene-una-subcarpeta-y-desktopini).

**Causa:** un patrón como `.obsidian/workspace.json` en el `.gitignore` de la raíz solo coincide con esa ruta exacta desde la raíz. Como el vault está en una subcarpeta, el archivo real es `<nombre-vault>/.obsidian/workspace.json` y no quedaba excluido.

**Solución:** empezar los patrones por `**/`, que significa "en cualquier subcarpeta":

```
**/.obsidian/workspace.json
**/.obsidian/workspace-mobile.json
**/.obsidian/cache/
**/.trash/
.DS_Store
desktop.ini
```

Si `workspace.json` ya se había subido, quitarlo con `git rm --cached "<nombre-vault>/.obsidian/workspace.json"`, commit y push.

### E19. API_SERVER_HOST=0.0.0.0 y clave compartida

```
API_SERVER_ENABLED=true
API_SERVER_HOST=0.0.0.0
API_SERVER_PORT=8642
API_SERVER_KEY=<clave>
```

**Duda:** ¿estas líneas son de la configuración de Obsidian y GitHub?

**Causa:** no. La integración con Obsidian solo añade `OBSIDIAN_VAULT_PATH`. Estas líneas son del servidor API de Hermes y venían de una prueba anterior con otra interfaz (Odysseus) que corría en Docker y necesitaba que Hermes escuchara en toda la red. Además, la clave se había pegado en un chat.

**Solución:**

1. Cambiar `API_SERVER_HOST` a `127.0.0.1`: Workspace corre en el mismo contenedor.
2. Generar una clave nueva con `openssl rand -hex 32` y sustituir `API_SERVER_KEY`. Esa clave da control total sobre Hermes, incluida la terminal, y **cualquier clave compartida en un chat, captura o mensaje debe sustituirse**.
3. Reiniciar el gateway y comprobar con `curl http://127.0.0.1:8642/health`.
4. Detener la otra interfaz (`docker compose down` en su carpeta), que ya no podrá conectar.

### E20. sudo: tailscale: command not found

```
sudo: tailscale: command not found
```

**Cuándo:** al ejecutar `sudo tailscale serve --bg 3000` en el contenedor.

**Causa:** Tailscale estaba instalado en otra máquina de la red, pero no dentro del contenedor. Cada máquina necesita su propia instalación.

**Solución:** seguir la [parte 5](05-tailscale.md): dar acceso a `/dev/net/tun` desde el host de Proxmox, instalar Tailscale en el contenedor y conectarlo con `sudo tailscale up --hostname=hermesagent`.

### E21. Usar Tailscale desde otra máquina

**Duda:** ¿se puede ejecutar `tailscale serve` en la otra máquina que ya tiene Tailscale?

**Respuesta:** así no funciona. `tailscale serve --bg 3000` publica el puerto 3000 **de la máquina donde se ejecuta**, donde no hay ninguna interfaz. Se podría publicar la dirección del contenedor desde la otra máquina, pero habría que hacer que Workspace escuchara en toda la red local, el tramo entre ambas máquinas iría sin cifrar y el acceso dependería de que esa máquina estuviera encendida. Por eso se instaló Tailscale en el contenedor.

### E22. Workspace no pide iniciar sesión

**Cuándo:** al abrir la dirección HTTPS por primera vez.

**Causa:** el servicio systemd de Workspace no estaba leyendo el archivo `.env`, así que arrancó sin `HERMES_PASSWORD` (y sin la clave del API, que provocó [E23](#e23-authentication-error-en-el-chat)).

**Solución:**

1. Comprobar que las variables existen, mostrando solo sus nombres:

```bash
grep -E '^(HERMES_PASSWORD|HERMES_API_TOKEN|TRUST_PROXY)=' ~/hermes-workspace/.env | cut -d= -f1
```

2. Indicar al servicio que cargue el `.env`:

```bash
export EDITOR=nano
```

```bash
systemctl --user edit hermes-workspace
```

```
[Service]
EnvironmentFile=/home/hermes/hermes-workspace/.env
```

3. Reiniciar y probar en una **ventana de incógnito**:

```bash
systemctl --user restart hermes-workspace
```

Mientras no esté resuelto, el riesgo es bajo (la dirección solo funciona en la red de Tailscale), pero si la red se comparte con otras personas conviene retirar la publicación con `sudo tailscale serve reset`.

### E23. Authentication error en el chat

```
⚠ Authentication error — check your API key in Settings
```

**Cuándo:** al escribirle a Hermes desde Workspace.

**Causa:** `HERMES_API_TOKEN` (en el `.env` de Workspace) era distinta de `API_SERVER_KEY` (en `~/.hermes/.env`), porque la clave se había cambiado en [E19](#e19-api_server_host0000-y-clave-compartida).

**Diagnóstico:** primero descartar OpenRouter: si Hermes responde por Telegram, la clave de OpenRouter está bien. Después, comprobar que `API_SERVER_KEY` aparece una sola vez y comparar ambas claves sin mostrarlas:

```bash
grep -c '^API_SERVER_KEY=' ~/.hermes/.env
```

```bash
a=$(grep '^API_SERVER_KEY=' ~/.hermes/.env | cut -d= -f2-); b=$(grep '^HERMES_API_TOKEN=' ~/hermes-workspace/.env | cut -d= -f2-); [ "$a" = "$b" ] && echo IGUALES || echo DISTINTAS
```

El resultado fue `DISTINTAS`.

**Solución:** copiar la clave automáticamente, sin pasar por el portapapeles:

```bash
key=$(grep '^API_SERVER_KEY=' ~/.hermes/.env | cut -d= -f2-); sed -i "s|^HERMES_API_TOKEN=.*|HERMES_API_TOKEN=$key|" ~/hermes-workspace/.env
```

Repetir la comparación (debe decir `IGUALES`) y reiniciar:

```bash
systemctl --user restart hermes-workspace
```

Si el error persiste, revisar **Settings → Connection** en Workspace: un token guardado ahí tiene prioridad sobre el `.env`. Debe ser igual a `API_SERVER_KEY` o estar vacío.

Si la comparación sigue diciendo `DISTINTAS` tras el `sed`, probablemente no existía la línea `HERMES_API_TOKEN=` (o estaba comentada con `#`): añadirla con nano y repetir.

### E24. Aviso de actualizaciones en Workspace

**Cuándo:** al entrar por primera vez a la interfaz.

**Decisión:** no actualizar desde la interfaz hasta tener todo funcionando, para no mezclar problemas, y hacerlo después desde la terminal, donde se ven los errores y se sabe qué se actualizó. Procedimiento en [mantenimiento](09-mantenimiento.md#actualizar-hermes). Las actualizaciones no afectan al vault, la sincronización ni la memoria de Hermes.

---

## Otros errores posibles

No ocurrieron en esta instalación, pero son los más probables en un montaje como este.

| Síntoma | Causa | Solución |
| --- | --- | --- |
| `Permission denied (publickey)` | La llave en GitHub no coincide con la del contenedor | Revisar que la deploy key está en ese repositorio y es la de `hermes` |
| `Could not resolve hostname github-vault` | `~/.ssh/config` mal creado | Revisarlo con `cat ~/.ssh/config` y rehacerlo con nano |
| El clone funciona pero el push falla con `denied` | Deploy key sin escritura | Borrarla y añadirla de nuevo marcando **Allow write access** |
| `Failed to connect to bus` con `systemctl --user` | Sesión abierta con `su` sin linger | `loginctl enable-linger hermes` como root, salir y volver a entrar |
| `ls -l /dev/net/tun`: No such file or directory | Faltan las líneas en `/etc/pve/lxc/<ID>.conf` | Añadirlas y `pct reboot <ID>` |
| `pnpm build` termina con `Killed` | Falta memoria | Más RAM o swap en Proxmox |
| Sesiones, skills o memoria dicen "Not Available" | El panel de Hermes no está activo | `systemctl --user status hermes-dashboard` y revisar la ruta de `ExecStart` |
| `Could not reach Hermes gateway` | Gateway detenido o sin `API_SERVER_ENABLED=true` | Reiniciar el gateway y probar `curl http://127.0.0.1:8642/health` |
| El inicio de sesión vuelve a la pantalla de login | Cookies antiguas | Borrar las cookies del sitio y reintentar |
| `tailscale serve` da error de certificados | HTTPS no activado en Tailscale | Activar **HTTPS Certificates** en DNS |
| Una nota muestra `<<<<<<<` y `>>>>>>>` | Se editó la misma nota en el PC y en el contenedor dentro del mismo intervalo | Elegir la versión correcta, borrar las marcas y sincronizar |

## Registros útiles

| Servicio | Comando |
| --- | --- |
| Sincronización del vault | `journalctl --user -u vault-sync.service -n 20` |
| Panel de Hermes | `journalctl --user -u hermes-dashboard -n 40` |
| Workspace | `journalctl --user -u hermes-workspace -f` (Ctrl+C para salir) |
| Estado general | `curl http://127.0.0.1:9119/api/status` |

Antes de compartir cualquier registro, comprueba que no aparece ninguna clave; si aparece, sustitúyela por `XXXX`.

[← Anterior: Hermes Workspace](06-hermes-workspace.md) · [Índice](../../README.es.md) · [Siguiente: Decisiones de diseño →](08-decisiones-de-diseno.md)
