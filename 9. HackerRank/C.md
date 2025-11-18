
# Hello World

```c
#include <stdio.h>

#include <string.h>

#include <math.h>

#include <stdlib.h>

  
int main()

{

char s[100];

scanf("%[^\n]%*c", &s);

/* Enter your code here. Read input from STDIN. Print output to STDOUT */

printf("Hello, World!\n");

printf("%s", s);

return 0;

}
```

# Playing with characters

```c
#include <stdio.h>

#include <string.h>

#include <math.h>

#include <stdlib.h>

#define MAX_LEN 100

  
int main()

{

  

/* Enter your code here. Read input from STDIN. Print output to STDOUT */

char ch;

char s[MAX_LEN];

char sen[MAX_LEN];

  
// Input character

scanf("%c", &ch);

  
// Input string

scanf("%s", s);


// To clear the newline character left in buffer

scanf("\n");


// Input sentence (with spaces)

scanf("%[^\n]%*c", sen);


// Output

printf("%c\n", ch);

printf("%s\n", s);

printf("%s\n", sen);

return 0;

}
```


# Functions

```c
#include <stdio.h>

/*

Add `int max_of_four(int a, int b, int c, int d)` here.

*/

int max_of_four(int a, int b, int c, int d) {

int max = a;

if (b > max) max = b;

if (c > max) max = c;

if (d > max) max = d;

return max;

}

int main() {

int a, b, c, d;

scanf("%d %d %d %d", &a, &b, &c, &d);

int ans = max_of_four(a, b, c, d);

printf("%d", ans);

return 0;

}
```

# Pointers

```c
#include <stdio.h>


void update(int *a,int *b) {

// Complete this function

int sum = *a + *b;

int diff = abs(*a - *b);

*a = sum;

*b = diff;

}


int main() {

int a, b;

int *pa = &a, *pb = &b;

scanf("%d %d", &a, &b);

update(pa, pb);

printf("%d\n%d", a, b);

  

return 0;

}
```

# Conditionals

```c
#include <assert.h>
#include <limits.h>
#include <math.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char* readline();

int main()
{
    char* n_endptr;
    char* n_str = readline();
    int n = strtol(n_str, &n_endptr, 10);

    if (n_endptr == n_str || *n_endptr != '\0') { exit(EXIT_FAILURE); }

    // Write Your Code Here
    if (n == 1) {
        printf("one");
    } 
    else if (n == 2) {
        printf("two");
    } 
    else if (n == 3) {
        printf("three");
    } 
    else if (n == 4) {
        printf("four");
    } 
    else if (n == 5) {
        printf("five");
    } 
    else if (n == 6) {
        printf("six");
    } 
    else if (n == 7) {
        printf("seven");
    } 
    else if (n == 8) {
        printf("eight");
    } 
    else if (n == 9) {
        printf("nine");
    } 
    else {
        printf("Greater than 9");
    }

    return 0;
}

char* readline() {
    size_t alloc_length = 1024;
    size_t data_length = 0;
    char* data = malloc(alloc_length);

    while (true) {
        char* cursor = data + data_length;
        char* line = fgets(cursor, alloc_length - data_length, stdin);

        if (!line) { break; }

        data_length += strlen(cursor);

        if (data_length < alloc_length - 1 || data[data_length - 1] == '\n') { break; }

        size_t new_length = alloc_length << 1;
        data = realloc(data, new_length);

        if (!data) { break; }

        alloc_length = new_length;
    }

    if (data[data_length - 1] == '\n') {
        data[data_length - 1] = '\0';
    }

    data = realloc(data, data_length);

    return data;
}
```

 