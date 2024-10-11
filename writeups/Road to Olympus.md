
# Enumeración hades

## nmap

```bash
└─$ sudo nmap -p- -sSCV -Pn --min-rate 5000 10.10.10.2 
Nmap scan report for hades.io (10.10.10.2)
Host is up (0.0000040s latency).
Not shown: 65533 closed tcp ports (reset)
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 9.6p1 Ubuntu 3ubuntu13.5 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   256 7e:85:1a:70:b5:2e:c6:35:73:9b:64:77:ba:5f:72:8b (ECDSA)
|_  256 0a:67:56:22:1e:a1:aa:05:44:f0:b9:05:75:6d:9c:36 (ED25519)
80/tcp open  http    Werkzeug/3.0.4 Python/3.12.3
|_http-server-header: Werkzeug/3.0.4 Python/3.12.3

```

Añadimos `hades.io` al `/etc/hosts` y revisamos la web.
## web

![[Pasted image 20240915022159.png]]

Revisando el código fuente, encuentro un hash perteneciente al usuario `cerbero`.

![[Pasted image 20240915022305.png]]

No parece ser un hash convencional, asique entro en [cyberchef](https://gchq.github.io/CyberChef/) y consigo descifrarlo.

![[Pasted image 20240915022804.png]]

siendo las credenciales de ssh `cerbero:P0seidón2022!`.

## ssh

![[Pasted image 20240915022920.png]]


PWN3D!


# Pivoting a poseidon

Para pivotar a la máquina Poseidón, primero hay que levantar una interfaz ligolo y activarla.

```
sudo ip tuntap add user patxasec mode tun ligolo
```

```
sudo ip link set ligolo up
```

Subo con `scp` el agente de ligolo a `hades`

![[Pasted image 20240915023655.png]]

![[Pasted image 20240915023720.png]]

inicio el agente.

![[Pasted image 20240915023859.png]]

![[Pasted image 20240915023923.png]]

escojo la sesión con cerbero y realizo el `start`

![[Pasted image 20240915024058.png]]

Ahora, con el tunel iniciado, es posible iniciar con la enumeración del objetivo.
## enumeración poseidon

Realizando un `ifconfig` desde ligolo, encuentro las diferentes redes dentro de `hades` y veo el siguiente objetivo: `20.20.20.2/24`

![[Pasted image 20240915024358.png]]

Nuestro siguiente paso es agregar una entrada a la tabla de enrutamiento para que Ligolo pueda enrutar el tráfico a través del túnel y llegar a la red de destino. Para ello, podemos utilizar el comando:

`sudo ip route add <Internal_Network> dev ligolo`

![[Pasted image 20240915031123.png]]

Una vez agregada la entrada, puedo descubrir que la siguiente máquina está en la ip `20.20.20.3`.

![[Pasted image 20240915031503.png]]
## nmap

```bash
sudo nmap -p- -sSCV -Pn --min-rate 5000 -v 20.20.20.3
Nmap scan report for poseidon.io (20.20.20.3)
Host is up (0.36s latency).
Not shown: 65533 closed tcp ports (reset)
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 8.4p1 Debian 5+deb11u3 (protocol 2.0)
| ssh-hostkey: 
|   3072 41:ea:e9:70:88:38:11:2b:1f:36:3a:cb:bd:1a:bb:e2 (RSA)
|   256 2c:d8:bf:01:05:7e:7a:70:38:7c:7b:f2:ba:54:4b:20 (ECDSA)
|_  256 20:37:e5:92:15:dc:69:18:dc:09:bb:69:74:6d:ae:c5 (ED25519)
80/tcp open  http    Apache httpd 2.4.54 ((Debian))
|_http-title: Dojos El Papapasito del mar
| http-methods: 
|_  Supported Methods: HEAD GET POST OPTIONS
|_http-server-header: Apache/2.4.54 (Debian)
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```
## web

Despues de meter la ip dentro del /etc/hosts, podemos ver poseidon.io  en el puerto 80.

![[Pasted image 20240915032229.png]]

Presionando en el botón "Buscar", me redirige a un buscador.

![[Pasted image 20240915032341.png]]

Después de intentar con diversos ataques manuales y automatizados como con herramientas del estilo a `sqlmap`, consigo encontrar la query adecuada.

![[Pasted image 20240915032526.png]]

Revisando las diferentes tablas, encuentro unos hashes en la tabla Atlantis junto a sus usuarios.

![[Pasted image 20240915032637.png]]

Una vez más, parecen estar intentando despistarnos y consigo descifrarlos mediante cyberchef.

![[Pasted image 20240915032801.png]]

quedando las credenciales como `megalodon:Templ02019!`
## ssh

![[Pasted image 20240915032935.png]]

![[Pasted image 20240915033038.png]]

PWN3D!

# pivoting a zeus

Para hacer un doble pivote con Ligolo-ng, necesitaremos crear una segunda interfaz de tun como la primera. Puedes llamarlo como quieras. Al nuestro lo llamamos ligolo-doble.

![[Pasted image 20240915034117.png]]

El siguiente paso es agregar un oyente en el puerto 11601 a la sesión existente de Ligolo-ng y redirigirlo a nuestra máquina.

`listener_add --addr 0.0.0.0:11601 --to 127.0.0.1:11601 --tcp`

Asegurándose de que se agregue con el siguiente comando:

`listener_list`

![[Pasted image 20240915034215.png]]

![[Pasted image 20241005203137.png]]

Subo con `scp` el agente de ligolo a `poseidon`

![[Pasted image 20240915033329.png]]

lo ejecuto usando la ip de la máquina previa.

![[Pasted image 20240915034255.png]]

Nuestro paso final es cambiar nuestra sesión al segundo punto de pivote, iniciar el túnel y luego agregar una ruta a la nueva red



![[Pasted image 20240915034638.png]]

![[Pasted image 20240915034803.png]]

## enumeración

Despues de enumerar la ip de la maquina poseidon en su interfaz eth1, encuentro usando fping, la ip de la tercera máquina objetivo.

![[Pasted image 20240915035048.png]]

## nmap

```bash
sudo nmap -p- -sSCV -Pn --min-rate 5000 -v 30.30.30.3
PORT    STATE SERVICE     VERSION
21/tcp  open  ftp         vsftpd 3.0.5
22/tcp  open  ssh         OpenSSH 8.9p1 Ubuntu 3ubuntu0.10 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   256 73:eb:17:b3:76:b1:26:63:b8:ed:14:2a:48:e9:c0:8c (ECDSA)
|_  256 e2:c9:56:85:e5:11:be:83:18:23:87:86:fb:94:3f:7f (ED25519)
80/tcp  open  http        Apache httpd 2.4.52 ((Ubuntu))
|_http-server-header: Apache/2.4.52 (Ubuntu)
| http-methods: 
|_  Supported Methods: POST OPTIONS HEAD GET
|_http-title: Apache2 Ubuntu Default Page: It works
139/tcp open  netbios-ssn Samba smbd 4.6.2
445/tcp open  netbios-ssn Samba smbd 4.6.2
```

## smb

Viendo que existe smb, empiezo enumerando con `enum4linux` para ver si hay algo de información visible.
Y parece que hay dos usuarios.

![[Pasted image 20240915035502.png]]

visto esto, me creo un reverse de rockyou para hacer fuerza bruta con ambos usuarios uasndo hydra.

![[Pasted image 20240915035910.png]]

Despues de llegar a la fila 6265611 del rockyou, encuentro la password.

![[Pasted image 20240915040615.png]]

## ftp

Conectando por ftp con las credenciales encontradas, encuentro un archivo .exe y me lo descargo.

![[Pasted image 20240915040811.png]]

buscando dentro del binario con strings, encuentro una linea sospechosa y ligeramente distinta a los hashes anteriores.

![[Pasted image 20240915041014.png]]

Desde la misma terminal, la descifro.

![[Pasted image 20240915041053.png]]

Pruebo a ver si es la contraseña del otro usuario que anteriormente he enumerado con enum4linux.

## ssh

![[Pasted image 20240915041308.png]]

POWN3D!!      HAPPY HACKING!!!