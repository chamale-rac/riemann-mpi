/*
 * Programa: openmp_riemann_suma.c
 * Autor: Samuel Chamalé
 * Fecha: 2024-10-23
 *
 * Descripción:
 * Este programa calcula la aproximación de una integral definida utilizando sumas de Riemann
 * de manera paralela con OpenMP. El programa recibe los límites de integración (a y b) y el número
 * de subintervalos (n) como argumentos de línea de comandos. Se utiliza la Regla del Punto
 * Medio para una mayor precisión en la aproximación.
 *
 * Compilación:
 *     gcc -fopenmp -O2 -o openmp_riemann_suma openmp_riemann_suma.c -lm
 *
 * Uso:
 *     ./openmp_riemann_suma <a> <b> <n> <numero_de_hilos>
 *     Donde:
 *         <a> : Límite inferior de integración (double)
 *         <b> : Límite superior de integración (double)
 *         <n> : Número de subintervalos (entero positivo)
 *         <numero_de_hilos> : Número de hilos de OpenMP (entero positivo)
 *
 * Ejemplo:
 *     ./openmp_riemann_suma 0 3.141592653589793 100000000 4
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <omp.h>

/* Definición de la función a integrar */
double funcion(double x) {
    return sin(x); // Puedes cambiar esta función según tus necesidades
}

/* Función para calcular la suma de Riemann utilizando la Regla del Punto Medio con OpenMP */
double calcular_suma_riemann_openmp(double a, double b, long n, int num_hilos) {
    double delta_x = (b - a) / n;
    double suma = 0.0;

    #pragma omp parallel for reduction(+:suma) num_threads(num_hilos)
    for (long i = 0; i < n; i++) {
        double x = a + (i + 0.5) * delta_x;
        suma += funcion(x) * delta_x;
    }

    return suma;
}

int main(int argc, char *argv[]) {
    if (argc != 5) {
        fprintf(stderr, "Uso: %s <a> <b> <n> <numero_de_hilos>\n", argv[0]);
        fprintf(stderr, "Donde:\n");
        fprintf(stderr, "    <a> : Límite inferior de integración (double)\n");
        fprintf(stderr, "    <b> : Límite superior de integración (double)\n");
        fprintf(stderr, "    <n> : Número de subintervalos (entero positivo)\n");
        fprintf(stderr, "    <numero_de_hilos> : Número de hilos de OpenMP (entero positivo)\n");
        return EXIT_FAILURE;
    }

    double a = atof(argv[1]);
    double b = atof(argv[2]);
    long n = atol(argv[3]);
    int num_hilos = atoi(argv[4]);

    if (n <= 0 || num_hilos <= 0) {
        fprintf(stderr, "El número de subintervalos y el número de hilos deben ser enteros positivos.\n");
        return EXIT_FAILURE;
    }

    printf("Aproximando la integral de sin(x) desde %.6f hasta %.6f con %ld subintervalos utilizando %d hilos.\n", a, b, n, num_hilos);

    /* Medición del tiempo de ejecución */
    double start_time = omp_get_wtime();

    /* Cálculo de la suma de Riemann */
    double suma_total = calcular_suma_riemann_openmp(a, b, n, num_hilos);

    double end_time = omp_get_wtime();
    double tiempo_ejecucion = end_time - start_time;

    printf("Resultado de la integral aproximada: %.12f\n", suma_total);
    printf("Tiempo de ejecución: %.6f segundos.\n", tiempo_ejecucion);

    return EXIT_SUCCESS;
}
