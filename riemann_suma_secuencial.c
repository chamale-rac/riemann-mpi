/*
 * Programa: riemann_suma_secuencial.c
 * Autor: Samuel Chamalé
 * Fecha: 2024-10-23
 *
 * Descripción:
 * Este programa calcula la aproximación de una integral definida utilizando sumas de Riemann
 * de manera secuencial. El programa recibe los límites de integración (a y b) y el número
 * de subintervalos (n) como argumentos de línea de comandos. Se utiliza la Regla del Punto
 * Medio para una mayor precisión en la aproximación.
 *
 * Compilación:
 *     gcc -o riemann_suma_secuencial riemann_suma_secuencial.c -lm
 *
 * Uso:
 *     ./riemann_suma_secuencial <a> <b> <n>
 *     Donde:
 *         <a> : Límite inferior de integración (double)
 *         <b> : Límite superior de integración (double)
 *         <n> : Número de subintervalos (entero positivo)
 *
 * Ejemplo:
 *     ./riemann_suma_secuencial 0 3.141592653589793 100000000
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

/* Definición de la función a integrar */
double funcion(double x) {
    return sin(x); // A quien lea esto, puede cambiar la función a integrar por cualquier otra función que desee.
}

/* Función para calcular la suma de Riemann utilizando la Regla del Punto Medio */
double calcular_suma_riemann(double a, double b, long n) {
    double delta_x = (b - a) / n;
    double suma = 0.0;
    double x;

    for (long i = 0; i < n; i++) {
        x = a + (i + 0.5) * delta_x;
        suma += funcion(x) * delta_x;
    }

    return suma;
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        fprintf(stderr, "Uso: %s <a> <b> <n>\n", argv[0]);
        fprintf(stderr, "Donde:\n");
        fprintf(stderr, "    <a> : Límite inferior de integración (double)\n");
        fprintf(stderr, "    <b> : Límite superior de integración (double)\n");
        fprintf(stderr, "    <n> : Número de subintervalos (entero positivo)\n");
        return EXIT_FAILURE;
    }

    double a = atof(argv[1]);
    double b = atof(argv[2]);
    long n = atol(argv[3]);

    if (n <= 0) {
        fprintf(stderr, "El número de subintervalos debe ser un entero positivo.\n");
        return EXIT_FAILURE;
    }

    printf("Aproximando la integral de sin(x) desde %.6f hasta %.6f con %ld subintervalos.\n", a, b, n);

    /* Medición del tiempo de ejecución */
    clock_t inicio = clock();

    /* Cálculo de la suma de Riemann */
    double suma_total = calcular_suma_riemann(a, b, n);

    clock_t fin = clock();
    double tiempo_ejecucion = ((double)(fin - inicio)) / CLOCKS_PER_SEC;

    printf("Resultado de la integral aproximada: %.12f\n", suma_total);
    printf("Tiempo de ejecución: %.6f segundos.\n", tiempo_ejecucion);

    return EXIT_SUCCESS;
}
