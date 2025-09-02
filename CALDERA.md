

# Qué es Caldera?

Es un marco de código abierto construido por el MITRE para ahorrar recursos mediante la automatización de evaluaciones de seguridad.

# Instalación (Ubuntu-Debian Based)

- Actualización 

```bash
sudo apt update -y && sudo apt upgrade -y
```

- Dependencias necesarias (python v < 3.12 & v > 3.8)

```bash
sudo apt install -y python3 python3-pip git gcc python3-dev upx-ucl
sudo pip3 install myst-parser
wget https://go.dev/dl/go1.20.3.linux-amd64.tar.gz  
sudo tar -C /usr/local -xzf go1.20.3.linux-amd64.tar.gz  
export PATH=$PATH:/usr/local/go/bin  
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc 
source ~/.bashrc
```

- Instrucciones oficiales

```bash
git clone https://github.com/mitre/caldera.git --recursive
cd caldera
pip3 install -r requirements.txt
python3 server.py --build
python3 server.py --insecure
```

Si todo ha funcionado bien, ir a:

- **localhost:8888**
- **127.0.0.1:8888**
- **0.0.0.0:8888**
# C2 prep



![[Pasted image 20250811093921.png]]

- [Terminologías de Caldera](https://caldera.readthedocs.io/en/2.8.0/Learning-the-terminology.html#:~:text=An%20ability%20is%20a%20specific,with%20profiles%20which%20use%20them.), simplificada: (categorías)  
    - **agentes:** software sencillo que conecta el objetivo al servidor Caldera  
    - **habilidades:** técnicas, tácticas, procedimientos (TTP)  
    - **adversarios:** habilidades agrupadas en un perfil  
    - **operaciones:** carreras manuales/automizadas de habilidades
- [Configuraciones](https://caldera.readthedocs.io/en/latest/Basic-Usage.html#agent-settings) de [Caldera](https://caldera.readthedocs.io/en/latest/Basic-Usage.html#agent-settings) simplificadas:  
    - **hechos:** (nombre.valor-score = datos) que se pueden utilizar para rellenar variables dentro de las habilidades de Caldera.  
    - **reglas:** restringir el uso de ciertos hechos especificando una acción (ALLOW o DENY) y un patrón para coincidir con el valor de los hechos.  
    - **planificadores:** módulos con la lógica para decidir qué capacidades utilizar y en qué orden durante una operación en marcha.  
    - **objetivos:** recopilación de metas basadas en hechos que deben alcanzarse durante una operación que se considere completa.  
    - **metas:** objetivos de hecho individuales con valores, conteos y relaciones específicas que deben ser satisfechas para que su objetivo asociado se considere completo.


# Desplegando agentes
Las configuraciones de agentes incluyen varios temporizadores como intervalos de balizamiento, perro guardián, etc., pero también 2 configuras para ejecutar comandos:

- **habilidades de bootstrap:** ejecutar comandos cuando nuevos faros de agente
- **habilidades de hombre muerto:** ejecutar comandos antes de la terminación del agente


![[Pasted image 20250811094919.png]]

Además, hay varios [agentes y plugins](https://caldera.readthedocs.io/en/latest/Plugin-library.html#plugin-library) ofrecidos por Caldera; En este test estoy ejecutando **Sandcat (también conocido como 54ndc47)**. Es el agente por defecto de Caldera que se comunica a través de la conexión HTTP/S. Otros agentes pueden comunicarse a través de HTML o TCP como se muestra a continuación.

**Nota:** También [puedes construir tu agente](https://caldera.readthedocs.io/en/latest/How-to-Build-Agents.html) para comunicarlo a través de http, tcp, udp, websocket, gist (vía Github) o dns.


![[Pasted image 20250811094339.png]]

![[Pasted image 20250811094718.png]]

Después de elegir un agente, elijo el sistema operativo de destino y modifico:

- `app.contact.http`: atacante ip y puerto (donde usted alberga Caldera)
- `agents.implant_name`**(opcional**): nombre de malware
- `agent.extensions`**(opcional**): echa un registro de [las extensiones de Sandcat](https://caldera.readthedocs.io/en/latest/plugins/sandcat/Sandcat-Details.html#extensions)

**Nota:** Asegúrese de revisar/modificar la carga útil y cualquier capacidad cuando sea necesario.


![[Pasted image 20250811095309.png]]

Ejecutado los comandos anteriores en un terminal establecerá una conexión exitosa como se muestra a continuación:

![[Pasted image 20250811094810.png]]

# Habilidades

Dentro de las **abilities**, podemos filtrar las tácticas y técnicas disponibles para nuestra plataforma y pluggins. C2 es lo que vamos a realizar en nuestra máquina de destino.

![[Pasted image 20250811100836.png]]


# Adversarios

Dentro de **Adversaries,** puede seleccionarse un perfil para ver sus **habilidades**, crear un nuevo perfil o importar uno.

![[Pasted image 20250811101235.png]]

# Operaciones

[Configuraciones de Operaciones](https://caldera.readthedocs.io/en/3.1.0/Basic-Usage.html#operations) :

- **Grupo:** colección de agentes para correr en contra
- **Autónomo:** Ejecute de forma autónoma o manual.
- **Planificador:** Elija la biblioteca lógica para usar para la operación.
- **Fuente de hecho:** Adjuntar una fuente de hechos para la operación de uso.
- **Tiempo de limpieza:** Hora de esperar a que cada comando de limpieza se complete.
- **Obfuscadores:** Seleccione un ofuscador para codar comandos.
- **Jitter:** agente check-in time with Caldera.
- **Visibilidad:** cuán visible es la operación a la defensa.

![[Pasted image 20250811101341.png]]

Cuando se ejecutan operaciones, hay una fuente de información que incluye el comando y su salida o error de fallo.

![[Pasted image 20250811101719.png]]

A pesar de estar en una operación automatizada, se nos permite ejecutar comandos manualmente.

![[Pasted image 20250811102446.png]]

Los informes de las operaciones realizadas se pueden descargar, incluyendo sus salidas de agente.

![[Pasted image 20250811102730.png]]

![[Pasted image 20250811102747.png]]