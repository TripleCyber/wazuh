# Guion: flujo del agente a TripleSOC (≈10 min)

Hilo de la historia: **"alguien conecta un USB no autorizado → en menos de un minuto el SOC lo ve en el dashboard y en Teams, y puede rastrearlo"**.

Apoyo visual: diagrama `Flujo-alertas-TripleSOC.pdf` (misma carpeta).

---

## 0. Antes de empezar (5 min antes, sin público)

| Comprobar | Cómo | Si falla |
|---|---|---|
| IP pública sin cambios | `Invoke-RestMethod https://api.ipify.org` | Pedir a Joel que la añada al NSG (puerto 1514) |
| Agente conectado | `Get-NetTCPConnection -RemotePort 1514` → `Established` | Si sale `SynSent` = firewall; ver plan B |
| Agente activo en el dashboard | Agents → DESKTOP-3BPAU4P = **Active** | Plan B |
| Sesión del dashboard abierta | Iniciar sesión justo antes (expira a los 15 min) | — |
| Teams abierto en el chat de alertas | — | — |
| Dispositivo de prueba a mano | Mando PS4 o memoria USB **no** incluidos en la lista de permitidos | — |

---

## 1. Introducción (30 s)

> "Os voy a enseñar el recorrido completo de un evento de seguridad: desde un equipo de usuario hasta que el SOC recibe la alerta. El caso de uso es la auditoría de dispositivos USB, porque es fácil de ver y es un riesgo real: fuga de datos por memorias o teléfonos, y ataques tipo BadUSB con teclados falsos."

**Mostrar:** diagrama completo.

---

## 2. El agente y su registro (1 min)

> "En cada equipo se instala el agente TripleSOC. Al instalarse se registra contra el gestor por el puerto 1515 usando una contraseña de alta; el gestor le entrega una clave única. A partir de ahí toda la comunicación va cifrada con esa clave."

> "El agente entra automáticamente en el grupo **triplesoc-endpoints**. Eso significa que no configuramos equipo por equipo: la configuración se define una vez en el gestor."

**Mostrar:** Dashboard → Agents → DESKTOP-3BPAU4P (estado Active, grupo triplesoc-endpoints).

**Dato técnico si preguntan:** el instalador (`install-agent-windows.ps1`) fija `logcollector.remote_commands=1`, necesario para que el agente acepte ejecutar comandos enviados por el gestor.

---

## 3. Configuración centralizada (1 min)

> "El gestor envía al grupo tres cosas: la configuración (`agent.conf`), el script de auditoría y la lista de USB permitidos. Si cambio el script o la lista en el gestor, se redistribuye y el agente se recarga solo, sin tocar el equipo."

> "La lista de permitidos acepta número de serie, VID:PID o identificador de instancia. Así TI puede autorizar, por ejemplo, las memorias corporativas y todo lo demás salta como no autorizado."

**Mostrar (opcional):** Dashboard → Agents management → Groups → triplesoc-endpoints → Files.

---

## 4. Detección en el equipo (1 min)

> "Cada 30 segundos el agente ejecuta el script como SYSTEM. El script mira tres tipos de dispositivo USB:
> - **Almacenamiento**: memorias y discos externos.
> - **Teléfonos y tablets** en modo transferencia de archivos.
> - **Dispositivos de entrada**: teclados, ratones y mandos, que es como se disfraza un BadUSB.
>
> Solo genera una línea cuando aparece un dispositivo **nuevo**; si no hay cambios, no envía nada, así no hay ruido."

> "El evento incluye el nombre del dispositivo, fabricante y producto (VID/PID), número de serie y si está autorizado o no."

---

## 5. Transporte al gestor (30 s)

> "El agente envía el evento al gestor por el puerto 1514, con el protocolo propio del agente y cifrado. La conexión siempre la abre el agente hacia el servidor: en el equipo del usuario no hace falta abrir ningún puerto."

---

## 6. Análisis en el gestor (1 min)

> "En el gestor, un decodificador propio extrae los campos del evento: estado, dispositivo, VID, PID y número de serie. Después lo evalúan nuestras reglas:"

| Regla | Nivel | Cuándo |
|---|---|---|
| 100911 **TripleSOC Security: Unauthorized Device Detected** | **12 (crítico)** | USB no autorizado |
| 100912 dispositivo USB autorizado conectado | 3 | USB en la lista de permitidos (queda registrado) |
| 100913 error en el script de auditoría | 5 | Si el script falla, también nos enteramos |

> "La regla crítica está mapeada a MITRE ATT&CK: T1200 (hardware añadido), T1091 (propagación por medios extraíbles) y T1052.001 (exfiltración por USB)."

---

## 7. Almacenamiento (30 s)

> "Las alertas se guardan en índices propios **triplesoc-alerts-AAAA.MM.DD**, uno por día, con una política que pasa a solo lectura los índices de más de 30 días."

---

## 8. DEMO en vivo (3 min)

1. **Decir:** "Voy a conectar un dispositivo que no está autorizado."
2. **Hacer:** conectar el mando o la memoria USB. **Esperar hasta 30 s** y rellenar el silencio:
   > "Ahora mismo el agente está ejecutando el script, detecta el dispositivo nuevo y lo envía cifrado al gestor…"
3. **Mostrar Teams:** llega la tarjeta con dispositivo, equipo, regla, nivel e **ID de evento**.
4. **Decir:** "La alerta llega a Teams porque es nivel 12 o superior. Cada alerta crítica se envía a dos destinos: un webhook con formato propio TripleSOC, pensado para conectar otros sistemas, y Teams para el equipo."
5. **Trazabilidad:** copiar la línea `id:"..."` de la tarjeta → Dashboard → Threat Hunting → pegar en la búsqueda.
   > "Con el ID de evento de Teams encuentro exactamente esa alerta en la consola, con todos sus detalles."
6. **Mostrar el detalle:** `usb.device`, `usb.vid`, `usb.pid`, `usb.serial`, `agent.name`, regla y MITRE.
7. **Cierre de la demo:** desconectar el dispositivo.

---

## 9. Cierre (30 s)

> "Resumen: se instala un agente, la configuración es centralizada, se detecta en 30 segundos como máximo, el tráfico va cifrado, las reglas y los índices son propios, y la alerta llega a Teams con un ID que permite rastrearla. Todo con la marca TripleSOC."

---

## Plan B (si el agente no está conectado)

- **Si el fallo es la IP o el firewall:** explicarlo con naturalidad.
  > "El entorno de pruebas limita el puerto del agente a mi IP y mi proveedor la cambia; en producción los equipos tendrían IP fija o VPN."
- **Enseñar una alerta real anterior:** en Threat Hunting, buscar `rule.id:100911`. La prueba con el mando PS4 del 29-09 tiene el ID `1790711202.1291246`, y ese mismo ID aparece en la tarjeta de Teams de ese día.
- **Demostrar la notificación en vivo con la alerta de prueba 100900:** se genera en el gestor (Coolify → terminal del manager).
  ```
  docker exec wazuh-manager-yf8u7icjiq4vdhetmea7rmfr sh -c 'echo "$(date "+%b %d %H:%M:%S") lab TRIPLESOC_INTEGRATION_TEST" >> /var/ossec/logs/active-responses.log'
  ```
  Llega a Teams igual que una alerta real.

---

## Preguntas probables

**¿Por qué hay que abrir el 1514? ¿No puede ir por el 443 con el proxy?**
El agente no usa HTTP, sino su propio protocolo cifrado. Un proxy web decide a dónde enviar el tráfico por el nombre del sitio, y el tráfico del agente no lo lleva. Un proxy TCP se quedaría con todo el 443 y rompería el dashboard. La alternativa es usar otro puerto que ya esté abierto y libre (por ejemplo, el 8080 si lo está).

**¿Qué pasa con un cable que solo carga?**
No se detecta porque no hay transferencia de datos y Windows no crea ningún dispositivo. Tampoco supone un riesgo de fuga.

**¿Detecta teléfonos?**
Sí, cuando están en modo transferencia de archivos (MTP/PTP). Se probó con un Samsung A25.

**¿Y dispositivos Bluetooth o el teclado del portátil?**
Se ignoran a propósito: el caso de uso son los dispositivos USB.

**¿Cómo se autoriza un USB?**
Se añade su número de serie o VID:PID a la lista de permitidos en el gestor. Llega a todos los equipos del grupo sin tocarlos.

**¿Y Linux o macOS?**
Hoy el script es para Windows. La arquitectura (grupo, script distribuido, reglas) es la misma; habría que añadir la versión del script para ese sistema.

**¿Cuánto tarda?**
Como máximo 30 segundos (la frecuencia del script) más unos segundos de procesamiento y envío.
