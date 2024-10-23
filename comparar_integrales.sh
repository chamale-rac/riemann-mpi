#!/bin/bash

# Script: comparar_integrales.sh
# Autor: Samuel Chamalé
# Fecha: 2024-10-23
#
# Descripción:
# Este script automatiza la ejecución de los programas de cálculo de integrales
# (versión secuencial y paralela con Open MPI), extrae los resultados y tiempos de
# ejecución, y realiza una comparación incluyendo el cálculo de speedup y eficiencia.
#
# Uso:
#     ./comparar_integrales.sh <a> <b> <n> <procesos_paralelos>
#     Donde:
#         <a> : Límite inferior de integración (double)
#         <b> : Límite superior de integración (double)
#         <n> : Número de subintervalos (entero positivo)
#         <procesos_paralelos> : Lista de números de procesos paralelos separados por espacio
#     Ejemplo:
#         ./comparar_integrales.sh 0 3.141592653589793 100000000 "2 4 8"

# Verificar que se proporcionen al menos 4 argumentos
if [ "$#" -lt 4 ]; then
    echo "Uso: $0 <a> <b> <n> \"<procesos_paralelos>\""
    echo "Ejemplo: $0 0 3.141592653589793 100000000 \"2 4 8\""
    exit 1
fi

# Parámetros de integración
A=$1
B=$2
N=$3
PROCESOS_PARALelos=($4)  # Convertir la cadena a un array

# Nombres de los programas
PROG_SEC="riemann_suma_secuencial"
PROG_MPI="mpi_riemann_suma"

# Archivos de compilación
SRC_SEC="riemann_suma_secuencial.c"
SRC_MPI="mpi_riemann_suma.c"

# Verificar si los archivos fuente existen
if [ ! -f "$SRC_SEC" ]; then
    echo "Error: Archivo fuente $SRC_SEC no encontrado."
    exit 1
fi

if [ ! -f "$SRC_MPI" ]; then
    echo "Error: Archivo fuente $SRC_MPI no encontrado."
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
mpicc -O2 -o "$PROG_MPI" "$SRC_MPI" -lm
if [ $? -ne 0 ]; then
    echo "Error: Falló la compilación de $PROG_MPI."
    exit 1
fi
echo "Compilación de $PROG_MPI exitosa."

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
echo "Versión Secuencial:"
echo "Integral Aproximada: $RESULT_SEC"
echo "Tiempo de Ejecución: $TIEMPO_SEC segundos"
echo "-------------------------------------------"

# Inicializar variables para resultados paralelos
declare -a RESULTS_MPI
declare -a TIEMPOS_MPI
declare -a SPEEDUP
declare -a EFICIENCIA

# Ejecutar las versiones paralelas
for PROC in "${PROCESOS_PARALelos[@]}"; do
    echo "Ejecutando la versión paralela con $PROC procesos..."
    OUTPUT_MPI=$(mpirun -np "$PROC" ./"$PROG_MPI" "$A" "$B" "$N")
    if [ $? -ne 0 ]; then
        echo "Error: Falló la ejecución de la versión paralela con $PROC procesos."
        exit 1
    fi

    # Extraer resultados de la versión paralela
    RESULT_MPI=$(echo "$OUTPUT_MPI" | grep "Resultado de la integral aproximada" | awk '{print $6}')
    TIEMPO_MPI_VAL=$(echo "$OUTPUT_MPI" | grep "Tiempo de ejecución" | awk '{print $4}')

    # Almacenar en arrays
    RESULTS_MPI+=("$RESULT_MPI")
    TIEMPOS_MPI+=("$TIEMPO_MPI_VAL")

    # Calcular speedup y eficiencia
    SPEEDUP_VAL=$(echo "scale=6; $TIEMPO_SEC / $TIEMPO_MPI_VAL" | bc -l)
    EFICIENCIA_VAL=$(echo "scale=6; $SPEEDUP_VAL / $PROC" | bc -l)

    SPEEDUP+=("$SPEEDUP_VAL")
    EFICIENCIA+=("$EFICIENCIA_VAL")

    echo "Versión Paralela con $PROC procesos:"
    echo "Integral Aproximada: $RESULT_MPI"
    echo "Tiempo de Ejecución: $TIEMPO_MPI_VAL segundos"
    echo "Speedup: $SPEEDUP_VAL"
    echo "Eficiencia: $EFICIENCIA_VAL"
    echo "-------------------------------------------"
done

# Mostrar resultados en una tabla
echo "Resumen de Resultados:"
echo "Tiempo de Ejecución (Secuencial): $TIEMPO_SEC segundos"
echo "Resultado de la Integral (Secuencial): $RESULT_SEC"
echo "Resultados y Speedup de la Versión Paralela:"
echo "--------------------------------------------------------------------------------------"
printf "| %-15s | %-20s | %-15s | %-10s | %-10s |\n" "Procesos" "Integral Aproximada" "Tiempo (s)" "Speedup" "Eficiencia"
echo "--------------------------------------------------------------------------------------"
for i in "${!PROCESOS_PARALelos[@]}"; do
    PROC=${PROCESOS_PARALelos[$i]}
    RESULT=${RESULTS_MPI[$i]}
    TIEMPO=${TIEMPOS_MPI[$i]}
    SP=${SPEEDUP[$i]}
    EF=${EFICIENCIA[$i]}
    printf "| %-15s | %-20s | %-15s | %-10s | %-10s |\n" "$PROC" "$RESULT" "$TIEMPO" "$SP" "$EF"
done
echo "--------------------------------------------------------------------------------------"

echo "Parámetros de entrada:"
echo "Límite Inferior: $A"
echo "Límite Superior: $B"
echo "Número de Subintervalos: $N"
echo "-------------------------------------------------------------"

exit 0
