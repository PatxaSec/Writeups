
| Comando de Bash | Ejemplo de uso                                          | Descripción en español                                                    |
| --------------- | ------------------------------------------------------- | ------------------------------------------------------------------------- |
| `grep`          | `grep "palabra_clave" archivo`                          | Busca una cadena de texto en un archivo                                   |
| `sed`           | `sed 's/old/new/g' archivo`                             | Reemplaza una cadena de texto en un archivo                               |
| `tr`            | `tr 'a-z' 'A-Z' < archivo`                              | Convierte a mayúsculas un archivo                                         |
| `awk`           | `awk '{print $1}' archivo`                              | Imprime la primera columna de un archivo                                  |
| `cut`           | `cut -c 1-10 archivo`                                   | Imprime las primeras 10 caracteres de cada línea de un archivo            |
| `paste`         | `paste archivo1 archivo2`                               | Combina dos archivos en uno, línea por línea                              |
| `sort`          | `sort archivo`                                          | Ordena un archivo alfabéticamente                                         |
| `uniq`          | `uniq archivo`                                          | Elimina líneas duplicadas en un archivo                                   |
| `diff`          | `diff archivo1 archivo2`                                | Compara dos archivos y muestra las diferencias                            |
| `patch`         | `patch archivo parche`                                  | Aplica un parche a un archivo                                             |
| `find`          | `find . -name "*.txt" -exec grep "palabra_clave" {} \;` | Busca archivos con una extensión específica y ejecuta un comando en ellos |
| `xargs`         | `find . -name "*.txt"`                                  | xargs grep "palabra_clave"`                                               |
| `head`          | `head -n 10 archivo`                                    | Muestra las primeras 10 líneas de un archivo                              |
| `tail`          | `tail -n 10 archivo`                                    | Muestra las últimas 10 líneas de un archivo                               |
| `wc`            | `wc -l archivo`                                         | Cuenta el número de líneas, palabras y caracteres en un archivo           |


| Patrón de regex | Descripción en español                                              | Ejemplo de uso                                                                            |
| --------------- | ------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `.`             | Coincide con cualquier carácter                                     | `grep "h.llo" archivo` (busca "hello", "hallo", etc.)                                     |
| `*`             | Coincide con 0 o más ocurrencias del carácter anterior              | `grep "a*" archivo` (busca "a", "aa", "aaa", etc.)                                        |
| `+`             | Coincide con 1 o más ocurrencias del carácter anterior              | `grep "a+" archivo` (busca "a", "aa", "aaa", etc., pero no coincide con la cadena vacía)  |
| `?`             | Coincide con 0 o 1 ocurrencia del carácter anterior                 | `grep "a?" archivo` (busca "a" o la cadena vacía)                                         |
| `{n}`           | Coincide con exactamente n ocurrencias del carácter anterior        | `grep "a{3}" archivo` (busca "aaa")                                                       |
| `{n,}`          | Coincide con n o más ocurrencias del carácter anterior              | `grep "a{3,}" archivo` (busca "aaa", "aaaa", etc.)                                        |
| `{n,m}`         | Coincide con al menos n y hasta m ocurrencias del carácter anterior | `grep "a{3,5}" archivo` (busca "aaa", "aaaa", "aaaaa")                                    |
| `^`             | Coincide con el inicio de la línea                                  | `grep "^hola" archivo` (busca líneas que comienzan con "hola")                            |
| `$`             | Coincide con el final de la línea                                   | `grep "hola$" archivo` (busca líneas que terminan con "hola")                             |
| `               | `                                                                   | Coincide con una de las opciones                                                          |
| `[]`            | Coincide con cualquier carácter dentro de los corchetes             | `grep "[abc]" archivo` (busca líneas que contienen "a", "b" o "c")                        |
| `[^]`           | Coincide con cualquier carácter que no esté dentro de los corchetes | `grep "[^abc]" archivo` (busca líneas que no contienen "a", "b" o "c")                    |
| `\`             | Escapa un carácter especial                                         | `grep "hola\." archivo` (busca líneas que contienen "hola.")                              |
| `\w`            | Coincide con cualquier carácter alfanumérico (letras y números)     | `grep "\w+" archivo` (busca líneas que contienen una o más palabras)                      |
| `\W`            | Coincide con cualquier carácter no alfanumérico                     | `grep "\W+" archivo` (busca líneas que contienen uno o más caracteres no alfanuméricos)   |
| `\d`            | Coincide con cualquier dígito                                       | `grep "\d+" archivo` (busca líneas que contienen uno o más dígitos)                       |
| `\D`            | Coincide con cualquier carácter que no sea un dígito                | `grep "\D+" archivo` (busca líneas que contienen uno o más caracteres que no son dígitos) |