# 8. Decisiones de diseño

🌐 [English](../en/08-design-decisions.md) · **Español**

[← Anterior: Solución de problemas](07-solucion-de-problemas.md) · [Índice](../../README.es.md) · [Siguiente: Mantenimiento →](09-mantenimiento.md)

Este documento explica por qué se eligió cada pieza frente a sus alternativas. El criterio general fue **priorizar opciones gratuitas, autoalojadas y sin exponer nada a internet**, aceptando servicios de pago solo donde aportan una mejora clara.

## Dónde vive Hermes: contenedor LXC

| Opción | Ventajas | Inconvenientes |
| --- | --- | --- |
| **Contenedor LXC** (elegida) | Muy ligero, arranca en segundos, consume poca RAM | Requiere ajustes para algunos dispositivos (Tailscale) |
| Máquina virtual | Aislamiento total, todo funciona sin ajustes | Más pesada en RAM y disco |
| VPS en la nube | Sin hardware propio | Coste mensual, datos fuera de casa |

Hermes no ejecuta los modelos localmente (los consume por API), así que no necesita GPU ni muchos recursos. Un contenedor con 2 núcleos y 4 GB de RAM es suficiente, incluida la compilación de la interfaz.

## Modelos: OpenRouter

| Opción | Ventajas | Inconvenientes |
| --- | --- | --- |
| **OpenRouter** (elegida) | Cientos de modelos con una sola clave, pago por uso, modelos gratuitos para pruebas | Los modelos gratuitos tienen límites estrictos |
| Modelos locales | Privacidad total, sin coste por uso | Requiere GPU potente |
| Nous Portal (suscripción) | Modelos, búsqueda, imágenes y voz en un solo pago | Coste fijo mensual |

Hermes exige modelos con al menos 64K tokens de contexto, y permite configurar proveedores de respaldo si el modelo principal falla.

## Sincronización del vault: GitHub

| Opción | Velocidad | Historial | Coste | Disponibilidad |
| --- | --- | --- | --- | --- |
| **GitHub (repo privado)** (elegida) | Minutos | Completo, con autoría | Gratis | Siempre online |
| Syncthing | Casi instantánea | No | Gratis | Requiere que ambos equipos coincidan encendidos (o el contenedor 24/7) |
| Obsidian Sync | Instantánea | Limitado | De pago | Siempre online, pero difícil de usar desde Linux sin interfaz |
| Gitea / Forgejo propio | Minutos | Completo | Gratis | Depende del servidor casero |

Para un agente que **edita notas de forma autónoma**, el historial es lo más valioso: cada cambio de Hermes queda registrado con su autor ("Hermes: fecha") y se puede deshacer. GitHub además funciona como copia de seguridad externa. Si la privacidad fuera prioritaria, Gitea o Forgejo en otro contenedor ofrecen lo mismo sin salir de casa.

## Acceso del contenedor al repositorio: deploy key

| Opción | Alcance si se filtra |
| --- | --- |
| **Deploy key** (elegida) | Solo ese repositorio |
| Llave SSH de la cuenta | Todos los repositorios de la cuenta |
| Token personal de acceso | Depende de los permisos, normalmente amplio |

La deploy key limita el daño posible: aunque alguien obtuviera la llave privada del contenedor, solo tendría acceso al repositorio del vault.

## Zona propia de Hermes en el vault

Hermes escribe sus notas nuevas en la carpeta `Hermes/` y solo modifica las notas personales cuando se le pide. Git combina sin problema cambios en archivos distintos; los conflictos solo aparecen cuando el PC y el contenedor editan **la misma nota** en el mismo intervalo de sincronización.

## Interfaz: Hermes Workspace

Se evaluaron cuatro opciones para tener una interfaz con muchas funciones, siempre disponible y sin usar la terminal:

| Opción | Qué es | Resultado |
| --- | --- | --- |
| Open WebUI | Interfaz de chat genérica compatible con OpenAI | Funciona con Hermes, pero solo ofrece chat |
| Odysseus | Espacio de trabajo de IA autoalojado con agentes, correo, investigación y documentos | Descartada (ver abajo) |
| **Hermes Workspace** (elegida) | Interfaz diseñada específicamente para Hermes | Elegida |
| Interfaz propia | Desarrollo a medida sobre el API de Hermes | Posible, pendiente como proyecto futuro |

**Por qué no Odysseus.** El objetivo era que Odysseus fuera solo la interfaz y que todas sus herramientas las usara y gestionara Hermes. No es posible de forma práctica: Odysseus **es un agente en sí mismo**, con sus propias herramientas, memoria y servidores MCP internos. Al conectar Hermes por el API compatible con OpenAI, Odysseus lo trata como un modelo más, y Hermes no puede usar el correo, la investigación o los documentos de Odysseus. Forzarlo exigiría depender de APIs internas no documentadas de un proyecto que cambia muy rápido. Incluso el fork comunitario que integra ambos los mantiene como agentes separados.

**Por qué Hermes Workspace.** Es una interfaz pensada para que Hermes sea el cerebro: chat con visualización de herramientas, memoria, skills, tareas programadas, servidores MCP, archivos y terminal. Funciona sobre Hermes sin modificarlo, usa licencia MIT, se instala como app en el móvil y no necesita Docker. Las herramientas que tenía Odysseus se obtienen dándoselas directamente a Hermes mediante skills y servidores MCP, de modo que funcionan igual desde la interfaz, Telegram o la terminal:

| Función de Odysseus | Equivalente controlado por Hermes |
| --- | --- |
| Chat y agentes | Hermes y sus subagentes |
| Memoria y skills | Memoria y skills de Hermes, editables desde Workspace |
| Correo y calendario | Skill Google Workspace incluida en Hermes |
| Notas y documentos | Vault de Obsidian y editor de archivos de Workspace |
| Tareas programadas | Tareas de Hermes, gestionables desde Workspace |
| Integraciones | Servidores MCP de Hermes, gestionables desde Workspace |

**Interfaz propia.** También es viable: una interfaz se comunica con el gateway (puerto 8642, API compatible con OpenAI, con eventos de herramientas en tiempo real) y con el panel (puerto 9119). La clave del API nunca debe estar en el código del navegador, así que haría falta un pequeño servidor intermedio que la guarde. Hermes incluso podría construirla y mantenerla dentro del contenedor.

## Acceso remoto: Tailscale dentro del contenedor

| Opción | Seguridad | Comentario |
| --- | --- | --- |
| **Tailscale en el contenedor + `tailscale serve`** (elegida) | Alta | HTTPS, solo dispositivos propios, sin puertos abiertos |
| Tailscale en otra máquina | Media | El tramo interno va sin cifrar y depende de otra máquina |
| Acceso por IP con HTTP | Media | Sin HTTPS: la PWA y el portapapeles quedan limitados |
| Abrir puertos en el router | Baja | Expone a internet un agente con acceso a terminal |

HTTPS no es solo una cuestión de seguridad: los navegadores solo permiten instalar la interfaz como app de verdad desde una dirección segura.

## Servicios solo en 127.0.0.1

El gateway, el panel y Workspace escuchan únicamente dentro del contenedor. Nada de la red local puede hablar con Hermes directamente; la única entrada es la interfaz, con contraseña y HTTPS, a través de Tailscale.

## Notificaciones: Telegram como complemento

La interfaz web es ideal para trabajar con Hermes, pero no está pensada para avisar por su cuenta. Telegram envía los resultados de las tareas programadas con notificación push. Ambos comparten la misma memoria y las mismas skills porque detrás está el mismo Hermes.

[← Anterior: Solución de problemas](07-solucion-de-problemas.md) · [Índice](../../README.es.md) · [Siguiente: Mantenimiento →](09-mantenimiento.md)
