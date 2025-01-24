
# install

```
sudo apt-get update
```

```
sudo apt-get install ca-certificates curl gnupg lsb-release
```

```
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable'
```

```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

- iniciar docker

```
sudo systemctl start docker
```

# cheatsheet

| Comando de Docker     | Ejemplo de uso                                                      | Descripción                                                                              |
| --------------------- | ------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `docker run`          | `docker run -p 8080:80 nginx`                                       | Ejecuta un contenedor a partir de una imagen                                             |
| `docker ps`           | `docker ps -a`                                                      | Muestra la lista de contenedores en ejecución                                            |
| `docker stop`         | `docker stop <container_id>`                                        | Detiene un contenedor en ejecución                                                       |
| `docker rm`           | `docker rm <container_id>`                                          | Elimina un contenedor detenido                                                           |
| `docker images`       | `docker images -a`                                                  | Muestra la lista de imágenes disponibles                                                 |
| `docker pull`         | `docker pull nginx:latest`                                          | Descarga una imagen desde un registro de Docker                                          |
| `docker push`         | `docker push <image_name>`                                          | Sube una imagen a un registro de Docker                                                  |
| `docker-compose up`   | `docker-compose up -d`                                              | Inicia un conjunto de contenedores definidos en un archivo docker-compose.yml            |
| `docker-compose down` | `docker-compose down`                                               | Detiene y elimina un conjunto de contenedores definidos en un archivo docker-compose.yml |
| `docker exec`         | `docker exec -it <container_id> bash`                               | Ejecuta un comando en un contenedor en ejecución                                         |
| `docker logs`         | `docker logs -f <container_id>`                                     | Muestra los registros de un contenedor en ejecución                                      |
| `docker inspect`      | `docker inspect -f '{{.NetworkSettings.IPAddress}}' <container_id>` | Muestra información detallada sobre un contenedor o imagen                               |
| `docker network`      | `docker network create <network_name>`                              | Crea una red de Docker para conectar contenedores                                        |
| `docker volume`       | `docker volume create <volume_name>`                                | Crea un volumen de Docker para persistir datos                                           |

```
docker build -t myimage .
```

```
docker run -it --net=host --rm myimage
o
docker run -it --net=host --rm --name mycontainer --restart always myimage
```

```
docker container commit contenedor nuevo

docker save nuevo -o nuevo.tar
```
