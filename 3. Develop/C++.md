
## 🔹 1. Hola Mundo

📘 **Teoría**

- Todo programa en C++ necesita una función `main()`.
    
- `std::cout` se usa para imprimir en consola, con `<<` como operador de inserción.
    
- `#include <iostream>` es obligatorio para entrada/salida.
    

💻 **Ejemplo de código**

```cpp
#include <iostream>

int main() {
    std::cout << "Hola, mundo!" << std::endl;
    return 0;
}
```

---

## 🔹 2. Tipos de datos y variables

📘 **Teoría**

- Tipos de valor: `int`, `float`, `double`, `char`, `bool`
    
- Tipos de referencia: `string`, punteros, referencias
    
- Variables pueden ser globales, locales o estáticas.
    

📊 **Tabla de tipos básicos**

|Tipo|Tamaño|Ejemplo|
|---|---|---|
|`char`|1|'A'|
|`int`|4|12345|
|`short`|2|-32768|
|`long`|8|123456789L|
|`float`|4|3.14f|
|`double`|8|2.718|
|`long double`|16|1.0L|
|`bool`|1|true/false|
|`std::string`|variable|"Hola"|

💻 **Ejemplo de código**

```cpp
#include <iostream>
#include <string>

int main() {
    int entero = 42;
    float real = 3.14f;
    bool ok = true;
    std::string texto = "Hola";

    std::cout << "int=" << entero 
              << ", float=" << real 
              << ", bool=" << ok 
              << ", string=" << texto << std::endl;

    return 0;
}
```

---

## 🔹 3. Operadores

📘 **Teoría**

- **Aritméticos**: `+ - * / %`
    
- **Relacionales**: `< <= > >= == !=`
    
- **Lógicos**: `&& || !`
    
- **Bitwise**: `& | ^ ~ << >>`
    
- **Asignación**: `= += -= *= /= %=`
    

💻 **Ejemplo de código**

```cpp
#include <iostream>

int main() {
    int a = 5, b = 2;

    std::cout << "Suma: " << a + b << std::endl;
    std::cout << "Resta: " << a - b << std::endl;
    std::cout << "Multiplicación: " << a * b << std::endl;
    std::cout << "División: " << a / b << std::endl;
    std::cout << "Módulo: " << a % b << std::endl;

    std::cout << "Mayor: " << (a > b) << std::endl;
    std::cout << "Igual: " << (a == b) << std::endl;

    return 0;
}
```

---

## 🔹 4. Condicionales

📘 **Teoría**

- `if`, `else if`, `else`
    
- `switch` para múltiples opciones
    

💻 **Ejemplo de código**

```cpp
#include <iostream>

int main() {
    int edad;
    std::cout << "Ingrese su edad: ";
    std::cin >> edad;

    if (edad >= 18) {
        std::cout << "Eres mayor de edad." << std::endl;
    } else {
        std::cout << "Eres menor de edad." << std::endl;
    }

    return 0;
}
```

---

## 🔹 5. Bucles

📘 **Teoría**

- `for` → número definido de iteraciones
    
- `while` → mientras la condición sea verdadera
    
- `do while` → se ejecuta al menos una vez
    

💻 **Ejemplo de código**

```cpp
#include <iostream>

int main() {
    // For
    for (int i = 1; i <= 5; i++)
        std::cout << "For: " << i << std::endl;

    // While
    int j = 1;
    while (j <= 5) {
        std::cout << "While: " << j << std::endl;
        j++;
    }

    // Do While
    int k = 1;
    do {
        std::cout << "Do While: " << k << std::endl;
        k++;
    } while (k <= 5);

    return 0;
}
```

---

## 🔹 6. Funciones

📘 **Teoría**

- Se declaran antes de `main` o en cabeceras (`.h`).
    
- Soportan sobrecarga y valores por defecto.
    

💻 **Ejemplo de código**

```cpp
#include <iostream>

// Prototipo
int Suma(int a, int b);

int main() {
    int resultado = Suma(3, 4);
    std::cout << "La suma es: " << resultado << std::endl;
    return 0;
}

// Definición
int Suma(int a, int b) {
    return a + b;
}
```

---

## 🔹 7. Estructuras (`struct`) y Clases (`class`)

📘 **Teoría**

- `struct` → por defecto todo público, tipos valor
    
- `class` → por defecto privado, soporte herencia y encapsulación
    

💻 **Ejemplo de código (struct)**

```cpp
#include <iostream>
#include <string>

struct Persona {
    std::string nombre;
    int edad;
};

int main() {
    Persona p1 = {"Ana", 25};
    std::cout << "Nombre: " << p1.nombre << ", Edad: " << p1.edad << std::endl;
    return 0;
}
```

💻 **Ejemplo de código (class)**

```cpp
#include <iostream>
#include <string>

class Persona {
public:
    std::string nombre;
    int edad;
};

int main() {
    Persona p1;
    p1.nombre = "Luis";
    p1.edad = 30;
    std::cout << "Nombre: " << p1.nombre << ", Edad: " << p1.edad << std::endl;
    return 0;
}
```

---

## 🔹 8. Módulos (Archivos y Cabeceras)

📘 **Teoría**

- Se separa en archivos `.h` (declaración) y `.cpp` (implementación).
    
- Se incluye con `#include "archivo.h"`.
    

💻 **Ejemplo de código**

**operaciones.h**

```cpp
int Sumar(int a, int b);
```

**operaciones.cpp**

```cpp
#include "operaciones.h"

int Sumar(int a, int b) {
    return a + b;
}
```

**main.cpp**

```cpp
#include <iostream>
#include "operaciones.h"

int main() {
    int resultado = Sumar(5, 7);
    std::cout << "Resultado: " << resultado << std::endl;
    return 0;
}
```

**Compilar**

```bash
g++ main.cpp operaciones.cpp -o programa
```
