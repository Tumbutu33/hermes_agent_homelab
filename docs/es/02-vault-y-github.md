# 2. Vault de Obsidian y GitHub

🌐 [English](../en/02-vault-and-github.md) · **Español**

[← Anterior: Preparar el LXC](01-preparar-lxc.md) · [Índice](../../README.es.md) · [Siguiente: Sincronización en el LXC →](03-sincronizacion-lxc.md)

En esta parte se crea el vault en el PC, se sube a un repositorio privado de GitHub y se configura el plugin que lo sincroniza automáticamente. Al terminar, las notas deben verse en GitHub.

## Cómo funciona la sincronización

GitHub actúa como **punto central**. No le "envía" nada a nadie: cada lado tiene una copia completa del vault y, cada pocos minutos, descarga (`pull`) los cambios nuevos y sube (`push`) los suyos.

| Lado | Copia del vault | Quién sincroniza |
| --- | --- | --- |
| PC | Carpeta que abre Obsidian | Plugin Obsidian Git |
| GitHub | Repositorio privado | — (siempre disponible) |
| Contenedor | `~/vault` | Script con timer de systemd |

Ventajas: el PC puede estar apagado mientras Hermes trabaja, y cada cambio queda en el historial (se puede ver y deshacer). Desventaja: no es instantáneo, puede tardar unos 10 minutos en llegar al otro lado.

## 2.1 Instalar Obsidian y Git

1. Instala **Obsidian** desde obsidian.md.
2. Instala **Git para Windows** desde git-scm.com con las opciones por defecto. Incluye **Git Bash** (la terminal que se usa en esta parte) y el gestor de credenciales que abre el navegador para iniciar sesión en GitHub.

## 2.2 Crear el vault

Un vault es simplemente una carpeta con archivos `.md`.

1. Crea una carpeta dedicada en el PC. Será la **raíz del repositorio**: no guardes en ella nada más que el vault, porque todo lo que contenga se subirá a GitHub.
2. En Obsidian, elige **Create new vault**, ponle un nombre (`<nombre-vault>`) y guárdalo dentro de esa carpeta.
3. Escribe una nota de prueba.

Estructura resultante:

```
carpeta-dedicada/          ← raíz del repositorio
├── .gitignore
├── README.md
└── <nombre-vault>/        ← el vault que abre Obsidian
    ├── .obsidian/         ← configuración de Obsidian
    └── (notas .md)
```

> **Nota:** en esta instalación el vault quedó dentro de una subcarpeta del repositorio. Funciona perfectamente, pero implica dos cosas: la ruta del vault en el contenedor es `~/vault/<nombre-vault>`, y los patrones del `.gitignore` deben empezar por `**/` (ver [E17](07-solucion-de-problemas.md#e17-el-repo-contiene-una-subcarpeta-y-desktopini) y [E18](07-solucion-de-problemas.md#e18-el-gitignore-no-se-aplica-dentro-del-vault)).

## 2.3 Crear el repositorio en GitHub

1. En GitHub pulsa **New repository**.
2. Nombre: `<repo-vault>`.
3. Marca **Private** (los repositorios privados son gratuitos).
4. Marca **Add a README file**.
5. Pulsa **Create repository**.

## 2.4 Abrir Git Bash en la raíz

1. En el explorador de Windows entra en la carpeta dedicada (la que contiene el vault).
2. Clic derecho en un espacio vacío → **Open Git Bash here** (en Windows 11, antes **Mostrar más opciones**).
3. Comprueba con `ls` que aparece la carpeta del vault.

## 2.5 Crear el .gitignore

Evita subir archivos que cambian constantemente y solo generarían conflictos. Los patrones empiezan por `**/` para que se apliquen dentro de la subcarpeta del vault:

```bash
printf '**/.obsidian/workspace.json\n**/.obsidian/workspace-mobile.json\n**/.obsidian/cache/\n**/.trash/\n.DS_Store\ndesktop.ini\n' > .gitignore
```

`desktop.ini` es un archivo de sistema que Windows crea en algunas carpetas y no sirve ni a Obsidian ni a Hermes. El archivo completo está en [`config/vault.gitignore.example`](../../config/vault.gitignore.example).

## 2.6 Convertir la carpeta en repositorio

Ejecuta uno por uno, con tu nombre y correo:

```bash
git init
```

```bash
git config user.name "Tu nombre"
```

```bash
git config user.email "tu-correo@ejemplo.com"
```

```bash
git add .
```

```bash
git commit -m "Vault inicial desde PC"
```

```bash
git branch -M main
```

```bash
git remote add origin https://github.com/<usuario-github>/<repo-vault>.git
```

Comprueba la dirección del remoto. Deben aparecer dos líneas con tu usuario y tu repo reales:

```bash
git remote -v
```

> **Error frecuente:** si aparece una dirección de ejemplo (como `TU-USUARIO/obsidian-vault`), el push fallará con `Repository not found`. Corrígela con `git remote set-url origin https://github.com/<usuario-github>/<repo-vault>.git` (ver [E14](07-solucion-de-problemas.md#e14-repository-not-found-desde-obsidian)).

## 2.7 Unir con el README y subir

El repositorio de GitHub ya tiene un README y la carpeta local tiene las notas: son dos historiales distintos y hay que unirlos antes de subir.

```bash
git pull origin main --allow-unrelated-histories --no-rebase
```

Si se abre un editor pidiendo un mensaje de merge, escribe `:wq` y pulsa Enter.

```bash
git push -u origin main
```

La primera vez, Windows abre el navegador para iniciar sesión en GitHub. El `-u` vincula la rama con GitHub de forma permanente.

## 2.8 Verificar en GitHub

Abre el repositorio, pestaña **Code**. Deben aparecer la carpeta del vault, `.gitignore` y `README.md`. La barra superior muestra el último commit, y el enlace **Commits** abre el historial.

Si algún archivo ignorado ya se había subido antes (por ejemplo, `desktop.ini`), quítalo del repositorio sin borrarlo del PC:

```bash
git rm --cached desktop.ini
```

```bash
git commit -m "Ignorar desktop.ini"
```

```bash
git push
```

## 2.9 Instalar el plugin Obsidian Git

1. En Obsidian: **Preferencias → Complementos comunitarios** (desactiva el modo restringido si es la primera vez).
2. **Explorar**, busca **Git** (autor: Vinzent03), instálalo y actívalo.

## 2.10 Configurar el plugin

En la configuración del plugin, sección **Automatic**:

| Ajuste | Valor | Motivo |
| --- | --- | --- |
| Use separate commit and push intervals | Desactivado | Un solo intervalo hace commit y push juntos |
| Auto commit-and-sync interval (minutes) | `5` | Con `0` (valor por defecto) los cambios nunca se suben solos |
| Auto commit-and-sync after stopping file edits | Activado | Espera a que dejes de escribir |
| Start the automatic commit-and-sync timer from the latest commit | Desactivado | No aporta nada aquí |
| Auto push interval (minutes) | `0` (en gris) | Solo se usa con intervalos separados |
| Auto pull interval (minutes) | `5` | Trae los cambios que hace Hermes |
| Auto commit-and-sync only staged files | Desactivado | Si se activa, ignora los cambios normales |
| Specify custom commit message on auto commit-and-sync | Desactivado | Si se activa, pide un mensaje cada 5 minutos |
| Commit message on auto commit-and-sync | `PC: {{date}}` | Distingue tus cambios de los de Hermes en el historial |

Vuelve al menú del plugin con la flecha **<** y activa también:

- **Pull on startup**: al abrir Obsidian descarga lo que Hermes hizo mientras estaba cerrado.
- **Pull on commit-and-sync**: descarga antes de subir y evita la mayoría de conflictos.

## 2.11 Primera sincronización desde Obsidian

Pulsa **Ctrl+P → Git: Commit-and-sync**.

- Si aparece el selector **"Select or create a new remote by typing its name and selecting it"**, elige `origin` y, si pregunta la rama, `main`. Solo ocurre la primera vez.
- **"No changes to commit"** no es un error: las notas ya están en un commit local. Usa **Ctrl+P → Git: Push** para enviarlas.

Comandos útiles de la paleta:

| Comando | Qué hace |
| --- | --- |
| Git: Commit-and-sync | Guarda, descarga y sube |
| Git: Pull | Solo descarga (por ejemplo, los cambios de Hermes) |
| Git: Push | Solo sube los commits pendientes |

## Comprobación

Crea una nota, espera unos minutos sin escribir y revisa GitHub. El último commit debe decir `PC: <fecha>`.

[← Anterior: Preparar el LXC](01-preparar-lxc.md) · [Índice](../../README.es.md) · [Siguiente: Sincronización en el LXC →](03-sincronizacion-lxc.md)
