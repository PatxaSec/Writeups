
## 🔹 1. Hola Mundo

📘 **Teoría**

- Todo programa en C comienza con la función `main()`.
    
- Se usa `#include <stdio.h>` para funciones de entrada/salida (`printf`, `scanf`).
    

💻 **Ejemplo de código**

```c
// Hola Mundo
#include <stdio.h>

int main() {
    printf("Hola, mundo!\n");
    return 0;
}
```

---

## 🔹 2. Tipos de datos y variables

📘 **Teoría**

- Los **tipos primitivos** dependen del compilador y arquitectura.
    
- Desde C99, se pueden usar enteros de ancho fijo (`int32_t`, `uint64_t`).
    
- Existen alias definidos en Windows API (`BYTE`, `WORD`, `DWORD`, `QWORD`).
    

📊 **Tabla resumen**

|Tipo en C|Tamaño típico|Ejemplo|
|---|---|---|
|`char`|1 byte|`'A'`|
|`int`|4 bytes|`42`|
|`float`|4 bytes|`3.14f`|
|`double`|8 bytes|`2.718`|
|`bool` (C99)|1 byte|`true/false`|
|`int32_t`|4 bytes|`-12345`|
|`uint64_t`|8 bytes|`123456ULL`|

📊 **Tabla de alias Windows API**

|Alias|Equivalente en C|Tamaño|
|---|---|---|
|`BYTE`|`unsigned char`|1 byte|
|`WORD`|`unsigned short`|2 bytes|
|`DWORD`|`unsigned long`|4 bytes|
|`QWORD`|`unsigned long long`|8 bytes|

💻 **Ejemplo de código**

```c
#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include <windows.h>

int main() {
    int entero = 42;
    float real = 3.14f;
    bool ok = true;
    DWORD id = 12345; // Windows API

    printf("int=%d, float=%f, bool=%d, DWORD=%lu\n", entero, real, ok, id);
    return 0;
}
```

---

## 🔹 3. Operadores

📘 **Teoría**  
Los operadores permiten manipular datos.  
Tipos principales:

- **Aritméticos**: `+ - * / %`
    
- **Relacionales**: `< <= > >= == !=`
    
- **Lógicos**: `&& || !`
    
- **Bitwise**: `& | ^ ~ << >>`
    
- **Asignación**: `= += -= *= /= %=`
    

💻 **Ejemplo de código**

```c
#include <stdio.h>

int main() {
    int a = 5, b = 2;

    printf("Suma: %d\n", a + b);
    printf("Resta: %d\n", a - b);
    printf("Multiplicación: %d\n", a * b);
    printf("División: %d\n", a / b);
    printf("Módulo: %d\n", a % b);

    printf("Mayor: %d\n", a > b);
    printf("Igual: %d\n", a == b);
    return 0;
}
```

---

## 🔹 4. Condicionales

📘 **Teoría**  
Los condicionales permiten ejecutar código dependiendo de una condición booleana.

- `if`, `else if`, `else`
    
- `switch (var) { case ... }`
    

💻 **Ejemplo de código**

```c
#include <stdio.h>

int main() {
    int edad;
    printf("Ingrese su edad: ");
    scanf("%d", &edad);

    if (edad >= 18) {
        printf("Eres mayor de edad.\n");
    } else {
        printf("Eres menor de edad.\n");
    }
    return 0;
}
```

---

## 🔹 5. Bucles

📘 **Teoría**  
Permiten repetir un bloque de código:

- `for` → número definido de iteraciones.
    
- `while` → mientras la condición sea verdadera.
    
- `do while` → se ejecuta al menos una vez.
    

💻 **Ejemplo de código**

```c
#include <stdio.h>

int main() {
    // For
    for (int i = 1; i <= 5; i++) {
        printf("For: %d\n", i);
    }

    // While
    int j = 1;
    while (j <= 5) {
        printf("While: %d\n", j);
        j++;
    }

    // Do While
    int k = 1;
    do {
        printf("Do While: %d\n", k);
        k++;
    } while (k <= 5);

    return 0;
}
```

---

## 🔹 6. Funciones

📘 **Teoría**

- Una función tiene **prototipo**, **definición** y **llamada**.
    
- Los parámetros se pasan **por valor** o **por referencia** (puntero).
    

💻 **Ejemplo de código**

```c
#include <stdio.h>

// Prototipo
int suma(int a, int b);

int main() {
    int resultado = suma(3, 4);
    printf("La suma es: %d\n", resultado);
    return 0;
}

// Definición
int suma(int a, int b) {
    return a + b;
}
```

---

## 🔹 7. Estructuras (`struct`)

📘 **Teoría**

- Agrupan varios tipos de datos bajo un mismo nombre.
    
- Pueden usarse con `typedef`.
    

💻 **Ejemplo de código**

```c
#include <stdio.h>

struct Persona {
    char nombre[20];
    int edad;
};

int main() {
    struct Persona p1 = {"Ana", 25};
    printf("Nombre: %s, Edad: %d\n", p1.nombre, p1.edad);
    return 0;
}
```

---

## 🔹 8. Módulos (archivos separados)

📘 **Teoría**

- C permite dividir el código en varios archivos.
    
- Un `.h` (cabecera) declara funciones/variables.
    
- Un `.c` (implementación) define las funciones.
    
- El archivo principal incluye el `.h`.
    

💻 **Ejemplo de código**

**main.c**

```c
#include <stdio.h>
#include "operaciones.h"

int main() {
    int resultado = sumar(5, 7);
    printf("Resultado: %d\n", resultado);
    return 0;
}
```

**operaciones.h**

```c
int sumar(int a, int b);
```

**operaciones.c**

```c
int sumar(int a, int b) {
    return a + b;
}
```

📌 Compilación:

```bash
gcc main.c operaciones.c -o programa
```
