/*
 * Programa: mpi_riemann_suma.c
 * Autor: Samuel Chamalé
 * Fecha: 2024-10-23
 *
 * Descripción:
 * Este programa utiliza Open MPI para aproximar la integral definida de una función
 * mediante sumas de Riemann de manera paralela. El programa recibe los límites de
 * integración (a y b) y el número de subintervalos (n) como argumentos de línea
 * de comandos. Cada proceso calcula una parte de la suma de Riemann utilizando la
 * Regla del Punto Medio y luego se realiza una reducción para obtener la suma total
 * que aproxima la integral.
 *
 * Compilación:
 *     mpicc -o mpi_riemann_suma mpi_riemann_suma.c -lm
 *
 * Uso:
 *     mpirun -np <número_de_procesos> ./mpi_riemann_suma <a> <b> <n>
 *     Donde:
 *         <a> : Límite inferior de integración (double)
 *         <b> : Límite superior de integración (double)
 *         <n> : Número de subintervalos (entero positivo)
 *
 * Ejemplo:
 *     mpirun -np 4 ./mpi_riemann_suma 0 3.141592653589793 100000000
 */

#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

/* Definición de la función a integrar */
double funcion(double x) {
    return sin(x); // A quien lea esto, puede cambiar la función a integrar por cualquier otra función que desee.
}

/* Estructura para almacenar los parámetros de la integral */
typedef struct {
    double a;      // Límite inferior de integración
    double b;      // Límite superior de integración
    long n;        // Número de subintervalos
} IntegracionParams;

/* Función para calcular la suma de Riemann utilizando la Regla del Punto Medio */
double calcular_suma_riemann(IntegracionParams params, long inicio, long fin) {
    double delta_x = (params.b - params.a) / params.n;
    double suma = 0.0;
    double x;

    for (long i = inicio; i < fin; i++) {
        x = params.a + (i + 0.5) * delta_x;
        suma += funcion(x) * delta_x;
    }

    return suma;
}

int main(int argc, char *argv[]) {
    int rank, size;
    IntegracionParams params;
    double suma_local = 0.0, suma_total = 0.0;
    double start_time, end_time;

    /* Inicialización de MPI */
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    /* Proceso raíz procesa los argumentos de línea de comandos */
    if (rank == 0) {
        if (argc != 4) {
            fprintf(stderr, "Uso: %s <a> <b> <n>\n", argv[0]);
            fprintf(stderr, "Donde:\n");
            fprintf(stderr, "    <a> : Límite inferior de integración (double)\n");
            fprintf(stderr, "    <b> : Límite superior de integración (double)\n");
            fprintf(stderr, "    <n> : Número de subintervalos (entero positivo)\n");
            MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
        }

        params.a = atof(argv[1]);
        params.b = atof(argv[2]);
        params.n = atol(argv[3]);

        if (params.n <= 0) {
            fprintf(stderr, "El número de subintervalos debe ser un entero positivo.\n");
            MPI_Abort(MPI_COMM_WORLD, EXIT_FAILURE);
        }

        printf("Aproximando la integral de sin(x) desde %.6f hasta %.6f con %ld subintervalos.\n",
               params.a, params.b, params.n);
    }

    /* Difusión de los parámetros a todos los procesos */
    MPI_Bcast(&params, sizeof(IntegracionParams), MPI_BYTE, 0, MPI_COMM_WORLD);

    /* Cálculo de la porción de trabajo para cada proceso */
    long subintervalos_por_proceso = params.n / size;
    long inicio = rank * subintervalos_por_proceso;
    long fin = (rank == size - 1) ? params.n : inicio + subintervalos_por_proceso;

    /* Sincronización antes del cálculo */
    MPI_Barrier(MPI_COMM_WORLD);
    start_time = MPI_Wtime();

    /* Cálculo de la suma local */
    suma_local = calcular_suma_riemann(params, inicio, fin);

    /* Reducción de las sumas locales para obtener la suma total */
    MPI_Reduce(&suma_local, &suma_total, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    /* Sincronización después del cálculo */
    MPI_Barrier(MPI_COMM_WORLD);
    end_time = MPI_Wtime();

    /* Proceso raíz muestra el resultado y el tiempo de ejecución */
    if (rank == 0) {
        printf("Resultado de la integral aproximada: %.12f\n", suma_total);
        printf("Tiempo de ejecución: %.6f segundos.\n", end_time - start_time);
    }

    /* Finalización de MPI */
    MPI_Finalize();

    return 0;
}
