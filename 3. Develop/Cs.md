
## 🔹 1. Hola Mundo

📘 **Teoría**

- Todo programa en C# necesita un `Main()` dentro de una clase.
    
- `Console.WriteLine()` se usa para imprimir en consola.
    

💻 **Ejemplo de código**

```csharp
using System;

class Program {
    static void Main() {
        Console.WriteLine("Hola, mundo!");
    }
}
```

---

## 🔹 2. Tipos de datos y variables

📘 **Teoría**

- Tipos de valor: `int`, `float`, `double`, `bool`, `char`, `struct`
    
- Tipos de referencia: `string`, `class`, `object`, `dynamic`
    
- C# es fuertemente tipado y seguro.
    

📊 **Tabla resumen de tipos básicos**

|Tipo|Tamaño|Ejemplo|
|---|---|---|
|`byte`|1|255|
|`short`|2|-32768|
|`int`|4|12345|
|`long`|8|123456789L|
|`float`|4|3.14f|
|`double`|8|2.718|
|`decimal`|16|100.5M|
|`bool`|1|true/false|
|`char`|2|'A'|
|`string`|variable|"Hola"|

💻 **Ejemplo de código**

```csharp
using System;

class Program {
    static void Main() {
        int entero = 42;
        float real = 3.14f;
        bool ok = true;
        string texto = "Hola";

        Console.WriteLine($"int={entero}, float={real}, bool={ok}, string={texto}");
    }
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

```csharp
using System;

class Program {
    static void Main() {
        int a = 5, b = 2;

        Console.WriteLine("Suma: " + (a + b));
        Console.WriteLine("Resta: " + (a - b));
        Console.WriteLine("Multiplicación: " + (a * b));
        Console.WriteLine("División: " + (a / b));
        Console.WriteLine("Módulo: " + (a % b));

        Console.WriteLine("Mayor: " + (a > b));
        Console.WriteLine("Igual: " + (a == b));
    }
}
```

---

## 🔹 4. Condicionales

📘 **Teoría**

- `if`, `else if`, `else`
    
- `switch` para múltiples opciones
    

💻 **Ejemplo de código**

```csharp
using System;

class Program {
    static void Main() {
        Console.Write("Ingrese su edad: ");
        int edad = int.Parse(Console.ReadLine());

        if (edad >= 18) {
            Console.WriteLine("Eres mayor de edad.");
        } else {
            Console.WriteLine("Eres menor de edad.");
        }
    }
}
```

---

## 🔹 5. Bucles

📘 **Teoría**

- `for` → número definido de iteraciones
    
- `while` → mientras la condición sea verdadera
    
- `do while` → se ejecuta al menos una vez
    
- `foreach` → recorre colecciones
    

💻 **Ejemplo de código**

```csharp
using System;

class Program {
    static void Main() {
        // For
        for (int i = 1; i <= 5; i++)
            Console.WriteLine("For: " + i);

        // While
        int j = 1;
        while (j <= 5) {
            Console.WriteLine("While: " + j);
            j++;
        }

        // Do While
        int k = 1;
        do {
            Console.WriteLine("Do While: " + k);
            k++;
        } while (k <= 5);

        // Foreach
        string[] nombres = { "Ana", "Luis", "Eva" };
        foreach (var nombre in nombres)
            Console.WriteLine("Foreach: " + nombre);
    }
}
```

---

## 🔹 6. Funciones (Métodos)

📘 **Teoría**

- En C# se llaman **métodos**.
    
- Pueden ser `static` o de instancia.
    
- Soportan sobrecarga y parámetros opcionales.
    

💻 **Ejemplo de código**

```csharp
using System;

class Program {
    static void Main() {
        int resultado = Suma(3, 4);
        Console.WriteLine("La suma es: " + resultado);
    }

    static int Suma(int a, int b) {
        return a + b;
    }
}
```

---

## 🔹 7. Estructuras (`struct`) y Clases (`class`)

📘 **Teoría**

- `struct` → tipos valor, ligeros, no heredan
    
- `class` → tipos referencia, soportan herencia y encapsulación
    

💻 **Ejemplo de código (struct)**

```csharp
using System;

struct Persona {
    public string Nombre;
    public int Edad;
}

class Program {
    static void Main() {
        Persona p1 = new Persona { Nombre = "Ana", Edad = 25 };
        Console.WriteLine($"Nombre: {p1.Nombre}, Edad: {p1.Edad}");
    }
}
```

💻 **Ejemplo de código (class)**

```csharp
using System;

class Persona {
    public string Nombre;
    public int Edad;
}

class Program {
    static void Main() {
        Persona p1 = new Persona { Nombre = "Luis", Edad = 30 };
        Console.WriteLine($"Nombre: {p1.Nombre}, Edad: {p1.Edad}");
    }
}
```

---

## 🔹 8. Módulos (Archivos y Namespaces)

📘 **Teoría**

- Se organiza el código en **archivos separados** y **namespaces**.
    
- Se usa `using` para incluir namespaces.
    

💻 **Ejemplo de código**

**Operaciones.cs**

```csharp
namespace MisOperaciones {
    public class Calculadora {
        public static int Sumar(int a, int b) {
            return a + b;
        }
    }
}
```

**Program.cs**

```csharp
using System;
using MisOperaciones;

class Program {
    static void Main() {
        int resultado = Calculadora.Sumar(5, 7);
        Console.WriteLine("Resultado: " + resultado);
    }
}
```

---
