#!/bin/bash

# Script: comparar_integrales.sh
# Autor: Samuel Chamalé
# Fecha: 2024-10-23
#
# Descripción:
# Este script automatiza la ejecución de los programas de cálculo de integrales
# (versión secuencial, paralela con Open MPI y paralela con OpenMP), extrae los resultados y tiempos de
# ejecución, y realiza una comparación incluyendo el cálculo de speedup y eficiencia.
#
# Uso:
#     ./comparar_integrales.sh <a> <b> <n> "<procesos_paralelos>" "<hilos_OpenMP>"
#     Donde:
#         <a> : Límite inferior de integración (double)
#         <b> : Límite superior de integración (double)
#         <n> : Número de subintervalos (entero positivo)
#         <procesos_paralelos> : Lista de números de procesos paralelos separados por espacio (ej. "2 4 8")
#         <hilos_OpenMP> : Lista de números de hilos para OpenMP separados por espacio (ej. "2 4 8")
#     Ejemplo:
#         ./comparar_integrales.sh 0 3.141592653589793 100000000 "2 4 8" "2 4 8"

# Verificar que se proporcionen al menos 5 argumentos
if [ "$#" -lt 5 ]; then
    echo "Uso: $0 <a> <b> <n> \"<procesos_paralelos>\" \"<hilos_OpenMP>\""
    echo "Ejemplo: $0 0 3.141592653589793 100000000 \"2 4 8\" \"2 4 8\""
    exit 1
fi

# Parámetros de integración
A=$1
B=$2
N=$3
PROCESOS_MPI=($4)     # Convertir la cadena a un array
HILOS_OPENMP=($5)    # Convertir la cadena a un array

# Nombres de los programas
PROG_SEC="riemann_suma_secuencial"
PROG_MPI_NAME="mpi_riemann_suma"
PROG_OPENMP_NAME="openmp_riemann_suma"

# Archivos de compilación
SRC_SEC="riemann_suma_secuencial.c"
SRC_MPI="mpi_riemann_suma.c"
SRC_OPENMP="openmp_riemann_suma.c"

# Verificar si los archivos fuente existen
if [ ! -f "$SRC_SEC" ]; then
    echo "Error: Archivo fuente $SRC_SEC no encontrado."
    exit 1
fi

if [ ! -f "$SRC_MPI" ]; then
    echo "Error: Archivo fuente $SRC_MPI no encontrado."
    exit 1
fi

if [ ! -f "$SRC_OPENMP" ]; then
    echo "Error: Archivo fuente $SRC_OPENMP no encontrado."
    exit 1
fi

# Compilar la versión secuencial
echo "Compilando la versión secuencial..."
gcc -O2 -o "$PROG_SEC" "$SRC_SEC" -lm
if [ $? -ne 0 ]; then
    echo "Error: Falló la compilación de $PROG_SEC."
    exit 1
fi
echo "Compilación de $PROG_SEC exitosa."

# Compilar la versión paralela con Open MPI
echo "Compilando la versión paralela con Open MPI..."
mpicc -O2 -o "$PROG_MPI_NAME" "$SRC_MPI" -lm
if [ $? -ne 0 ]; then
    echo "Error: Falló la compilación de $PROG_MPI_NAME."
    exit 1
fi
echo "Compilación de $PROG_MPI_NAME exitosa."

# Compilar la versión paralela con OpenMP
echo "Compilando la versión paralela con OpenMP..."
gcc -fopenmp -O2 -o "$PROG_OPENMP_NAME" "$SRC_OPENMP" -lm
if [ $? -ne 0 ]; then
    echo "Error: Falló la compilación de $PROG_OPENMP_NAME."
    exit 1
fi
echo "Compilación de $PROG_OPENMP_NAME exitosa."

echo "-------------------------------------------"

# Ejecutar la versión secuencial
echo "Ejecutando la versión secuencial..."
OUTPUT_SEC=$("./$PROG_SEC" "$A" "$B" "$N")
if [ $? -ne 0 ]; then
    echo "Error: Falló la ejecución de la versión secuencial."
    exit 1
fi

# Extraer resultados de la versión secuencial
RESULT_SEC=$(echo "$OUTPUT_SEC" | grep "Resultado de la integral aproximada" | awk '{print $6}')
TIEMPO_SEC=$(echo "$OUTPUT_SEC" | grep "Tiempo de ejecución" | awk '{print $4}')

# Formatear tiempos con 6 decimales
TIEMPO_SEC=$(printf "%.6f" "$TIEMPO_SEC")

echo "Versión Secuencial:"
echo "Integral Aproximada: $RESULT_SEC"
echo "Tiempo de Ejecución: $TIEMPO_SEC segundos"
echo "-------------------------------------------"

# Inicializar variables para resultados paralelos MPI
declare -a RESULTS_MPI
declare -a TIEMPOS_MPI
declare -a SPEEDUP_MPI
declare -a EFICIENCIA_MPI

# Ejecutar las versiones paralelas con Open MPI
for PROC in "${PROCESOS_MPI[@]}"; do
    echo "Ejecutando la versión paralela con $PROC procesos (MPI)..."
    OUTPUT_MPI=$(mpirun -np "$PROC" ./"$PROG_MPI_NAME" "$A" "$B" "$N")
    if [ $? -ne 0 ]; then
        echo "Error: Falló la ejecución de la versión paralela con $PROC procesos (MPI)."
        exit 1
    fi

    # Extraer resultados de la versión paralela MPI
    RESULT_MPI=$(echo "$OUTPUT_MPI" | grep "Resultado de la integral aproximada" | awk '{print $6}')
    TIEMPO_MPI_VAL=$(echo "$OUTPUT_MPI" | grep "Tiempo de ejecución" | awk '{print $4}')

    # Formatear tiempos con 6 decimales
    TIEMPO_MPI_VAL=$(printf "%.6f" "$TIEMPO_MPI_VAL")

    # Almacenar en arrays
    RESULTS_MPI+=("$RESULT_MPI")
    TIEMPOS_MPI+=("$TIEMPO_MPI_VAL")

    # Calcular speedup y eficiencia
    SPEEDUP_VAL=$(echo "scale=6; $TIEMPO_SEC / $TIEMPO_MPI_VAL" | bc -l)
    EFICIENCIA_VAL=$(echo "scale=6; $SPEEDUP_VAL / $PROC" | bc -l)

    # Asegurar que los valores tengan un 0 antes del punto decimal
    SPEEDUP_VAL=$(printf "%.6f" "$SPEEDUP_VAL")
    EFICIENCIA_VAL=$(printf "%.6f" "$EFICIENCIA_VAL")

    SPEEDUP_MPI+=("$SPEEDUP_VAL")
    EFICIENCIA_MPI+=("$EFICIENCIA_VAL")

    echo "Versión Paralela con $PROC procesos (MPI):"
    echo "Integral Aproximada: $RESULT_MPI"
    echo "Tiempo de Ejecución: $TIEMPO_MPI_VAL segundos"
    echo "Speedup: $SPEEDUP_VAL"
    echo "Eficiencia: $EFICIENCIA_VAL"
    echo "-------------------------------------------"
done

# Inicializar variables para resultados paralelos OpenMP
declare -a RESULTS_OPENMP
declare -a TIEMPOS_OPENMP
declare -a SPEEDUP_OPENMP
declare -a EFICIENCIA_OPENMP

# Ejecutar las versiones paralelas con OpenMP
for HILOS in "${HILOS_OPENMP[@]}"; do
    echo "Ejecutando la versión paralela con $HILOS hilos (OpenMP)..."
    # Establecer el número de hilos
    export OMP_NUM_THREADS=$HILOS
    OUTPUT_OPENMP=$(./"$PROG_OPENMP_NAME" "$A" "$B" "$N" "$HILOS")
    if [ $? -ne 0 ]; then
        echo "Error: Falló la ejecución de la versión paralela con $HILOS hilos (OpenMP)."
        exit 1
    fi

    # Extraer resultados de la versión paralela OpenMP
    RESULT_OPENMP=$(echo "$OUTPUT_OPENMP" | grep "Resultado de la integral aproximada" | awk '{print $6}')
    TIEMPO_OPENMP_VAL=$(echo "$OUTPUT_OPENMP" | grep "Tiempo de ejecución" | awk '{print $4}')

    # Formatear tiempos con 6 decimales
    TIEMPO_OPENMP_VAL=$(printf "%.6f" "$TIEMPO_OPENMP_VAL")

    # Almacenar en arrays
    RESULTS_OPENMP+=("$RESULT_OPENMP")
    TIEMPOS_OPENMP+=("$TIEMPO_OPENMP_VAL")

    # Calcular speedup y eficiencia
    SPEEDUP_VAL=$(echo "scale=6; $TIEMPO_SEC / $TIEMPO_OPENMP_VAL" | bc -l)
    EFICIENCIA_VAL=$(echo "scale=6; $SPEEDUP_VAL / $HILOS" | bc -l)

    # Asegurar que los valores tengan un 0 antes del punto decimal
    SPEEDUP_VAL=$(printf "%.6f" "$SPEEDUP_VAL")
    EFICIENCIA_VAL=$(printf "%.6f" "$EFICIENCIA_VAL")

    SPEEDUP_OPENMP+=("$SPEEDUP_VAL")
    EFICIENCIA_OPENMP+=("$EFICIENCIA_VAL")

    echo "Versión Paralela con $HILOS hilos (OpenMP):"
    echo "Integral Aproximada: $RESULT_OPENMP"
    echo "Tiempo de Ejecución: $TIEMPO_OPENMP_VAL segundos"
    echo "Speedup: $SPEEDUP_VAL"
    echo "Eficiencia: $EFICIENCIA_VAL"
    echo "-------------------------------------------"
done

# Mostrar resultados en tablas
echo "Resumen de Resultados:"
echo "--------------------------------------------------------------------------------------"
echo "Tiempo de Ejecución (Secuencial): $TIEMPO_SEC segundos"
echo "Resultado de la Integral (Secuencial): $RESULT_SEC"
echo ""

# Tabla de Resultados Paralelos con Open MPI
echo "Resultados y Speedup de la Versión Paralela con Open MPI:"
echo "--------------------------------------------------------------------------------------"
printf "| %-15s | %-20s | %-15s | %-10s | %-10s |\n" "Procesos" "Integral Aproximada" "Tiempo (s)" "Speedup" "Eficiencia"
echo "--------------------------------------------------------------------------------------"
for i in "${!PROCESOS_MPI[@]}"; do
    PROC=${PROCESOS_MPI[$i]}
    RESULT=${RESULTS_MPI[$i]}
    TIEMPO=${TIEMPOS_MPI[$i]}
    SP=${SPEEDUP_MPI[$i]}
    EF=${EFICIENCIA_MPI[$i]}
    printf "| %-15s | %-20s | %-15s | %-10s | %-10s |\n" "$PROC" "$RESULT" "$TIEMPO" "$SP" "$EF"
done
echo "--------------------------------------------------------------------------------------"
echo ""

# Tabla de Resultados Paralelos con OpenMP
echo "Resultados y Speedup de la Versión Paralela con OpenMP:"
echo "--------------------------------------------------------------------------------------"
printf "| %-15s | %-20s | %-15s | %-10s | %-10s |\n" "Hilos" "Integral Aproximada" "Tiempo (s)" "Speedup" "Eficiencia"
echo "--------------------------------------------------------------------------------------"
for i in "${!HILOS_OPENMP[@]}"; do
    HILOS=${HILOS_OPENMP[$i]}
    RESULT=${RESULTS_OPENMP[$i]}
    TIEMPO=${TIEMPOS_OPENMP[$i]}
    SP=${SPEEDUP_OPENMP[$i]}
    EF=${EFICIENCIA_OPENMP[$i]}
    printf "| %-15s | %-20s | %-15s | %-10s | %-10s |\n" "$HILOS" "$RESULT" "$TIEMPO" "$SP" "$EF"
done
echo "--------------------------------------------------------------------------------------"
echo ""

echo "Parámetros de entrada:"
echo "Límite Inferior: $A"
echo "Límite Superior: $B"
echo "Número de Subintervalos: $N"
echo "Número de Procesos Paralelos (MPI): ${PROCESOS_MPI[@]}"
echo "Número de Hilos (OpenMP): ${HILOS_OPENMP[@]}"
echo "-------------------------------------------------------------"

exit 0
