#!/bin/bash

# Extraer la temperatura exterior del resultado de inxi
temperature=$(inxi -w | grep -oP 'temperature:\s*\K[0-9]+')

# Obtener el número de procesos en ejecución y el porcentaje de memoria utilizada utilizando inxi
process_count=$(inxi -c 0 | grep -oP 'Procs:\s*\K[0-9]+')
memory_usage=$(inxi -m | grep -oP 'Mem:\s*\K[0-9]+\.[0-9]+\/[0-9]+\.[0-9]+ MiB' | grep -oP '[0-9]+\.[0-9]+')

# Establecer el valor de temperatura límite
temperatura_limite=15

# Verificar si la temperatura supera el límite
if [ "$temperature" -gt "$temperatura_limite" ]; then
    # Advertencia
    echo "Advertencia: La temperatura exterior es superior a $temperatura_limite°C."
    
    # Mostrar información adicional
    echo "Número de procesos en ejecución: $process_count"
    #echo "Porcentaje de memoria utilizada: $memory_usage%"

    # Enviar mensaje a todos los usuarios conectados local y remotamente
    wall "Advertencia: La temperatura exterior es superior a $temperatura_limite°C. Consulte el sistema para más detalles."
    wall "Número de procesos en ejecución: $process_count"
    #wall "Porcentaje de memoria utilizada: $memory_usage%"

else
    echo "La temperatura exterior está dentro del rango normal."
    echo "Número de procesos en ejecución: $process_count"
    #echo "Porcentaje de memoria utilizada: $memory_usage%"
fi

