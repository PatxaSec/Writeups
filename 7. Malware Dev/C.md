

**Variables y Tipos de Datos**

|Tipo de Dato|Descripción|Ejemplo|
|---|---|---|
|`int`|Entero|`int x = 5;`|
|`float`|Número de punto flotante|`float y = 3.14;`|
|`char`|Carácter|`char c = 'a';`|
|`double`|Número de punto flotante de doble precisión|`double z = 3.14159;`|
|`void`|Sin valor|`void *ptr;`|

**Operadores**

|Operador|Descripción|Ejemplo|
|---|---|---|
|`+`|Adición|`int x = 5; int y = x + 3;`|
|`-`|Sustracción|`int x = 5; int y = x - 3;`|
|`*`|Multiplicación|`int x = 5; int y = x * 3;`|
|`/`|División|`int x = 5; int y = x / 3;`|
|`%`|Módulo|`int x = 5; int y = x % 3;`|
|`==`|Igualdad|`int x = 5; if (x == 5) { ... }`|
|`!=`|Desigualdad|`int x = 5; if (x != 5) { ... }`|
|`>`|Mayor que|`int x = 5; if (x > 3) { ... }`|
|`<`|Menor que|`int x = 5; if (x < 3) { ... }`|
|`>=`|Mayor o igual que|`int x = 5; if (x >= 3) { ... }`|
|`<=`|Menor o igual que|`int x = 5; if (x <= 3) { ... }`|

**Estructuras de Control**

|Estructura de Control|Descripción|Ejemplo|
|---|---|---|
|`if`|Declaración condicional|`if (x > 5) { ... }`|
|`if-else`|Declaración condicional con alternativa|`if (x > 5) { ... } else { ... }`|
|`switch`|Declaración de selección|`switch (x) { case 1: ...; break; case 2: ...; break; }`|
|`while`|Bucle while|`int x = 0; while (x < 5) { ...; x++; }`|
|`for`|Bucle for|`for (int x = 0; x < 5; x++) { ... }`|
|`do-while`|Bucle do-while|`int x = 0; do { ...; x++; } while (x < 5);`|

**Funciones**

|Función|Descripción|Ejemplo|
|---|---|---|
|`main`|Punto de entrada del programa|`int main() { ... }`|
|`printf`|Imprimir salida formateada|`printf("Hola, mundo!\n");`|
|`scanf`|Leer entrada formateada|`scanf("%d", &x);`|
|`malloc`|Asignación de memoria dinámica|`int *ptr = malloc(sizeof(int));`|
|`free`|Liberación de memoria dinámica|`free(ptr);`|

**Arreglos y Cadenas**

|Arreglo/Cadena|Descripción|Ejemplo|
|---|---|---|
|`array`|Declaración de arreglo|`int arr[5];`|
|`string`|Declaración de cadena|`char str[10];`|
|`strlen`|Longitud de cadena|`char str[] = "hola"; int len = strlen(str);`|
|`strcpy`|Copia de cadena|`char str1[] = "hola"; char str2[10]; strcpy(str2, str1);`|
|`strcmp`|Comparación de cadenas|`char str1[] = "hola"; char str2[] = "mundo"; if (strcmp(str1, str2) == 0) { ... }`|

**Punteros**

| Puntero | Descripción                  | Ejemplo                                                        |
| ------- | ---------------------------- | -------------------------------------------------------------- |
| `*`     | Operador de desreferencia    | `int x = 5; int *ptr = &x; int y = *ptr;`                      |
| `&`     | Operador de dirección        | `int x = 5; int *ptr = &x;`                                    |
| `->`    | Operador de acceso a miembro | `struct Persona { int edad; }; struct Persona p; p.edad = 25;` |