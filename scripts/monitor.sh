#!/bin/bash

# Intervalo de refresco a 20 segundos
REFRESCO=10

# Función para dibujar una barra de porcentaje
dibujar_barra() {
    local porcentaje=$1
    local longitud=25
    local completados=$((porcentaje * longitud / 100))
    local vacios=$((longitud - completados))

    local barra=""
    for ((i=0; i<completados; i++)); do barra+="█"; done
    for ((i=0; i<vacios; i++)); do barra+="░"; done

    if [ "$porcentaje" -ge 85 ]; then
        echo -e "\e[31m[$barra] ${porcentaje}%\e[0m"
    elif [ "$porcentaje" -ge 60 ]; then
        echo -e "\e[33m[$barra] ${porcentaje}%\e[0m"
    else
        echo -e "\e[32m[$barra] ${porcentaje}%\e[0m"
    fi
}

# Bucle infinito
while true; do
    clear

    # Cabecera Ampliada
    echo -e "\e[1;36m=================================================================================\e[0m"
    echo -e "\e[1;32m                   PANEL DE MONITOREO AVANZADO - SISTEMA & DOCKER                \e[0m"
    echo -e "\e[1;36m=================================================================================\e[0m"
    echo -e " Fecha/Hora : \e[1;33m$(date '+%Y-%m-%d %H:%M:%S')\e[0m"
    echo -e " Uptime     : \e[1;37m$(uptime -p)\e[0m"
    echo -e " Carga (Load): \e[1;37m$(uptime | awk -F'load average:' '{ print $2 }')\e[0m"
    echo -e "\e[1;36m---------------------------------------------------------------------------------\e[0m"

    # --- 1. RECURSOS DEL SISTEMA OPERATIVO ---
    echo -e "\e[1;34m[ RECURSOS GENERALES DEL SO ]\e[0m"

    # CPU Usage
    cpu_usg=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
    cpu_int=${cpu_usg%.*}
    echo -n " CPU Usada  : "
    dibujar_barra "$cpu_int"

    # RAM Usage
    read ram_total ram_used < <(free -m | awk 'NR==2{print $2, $3}')
    ram_porc=$((ram_used * 100 / ram_total))
    echo -n " RAM Usada  : "
    dibujar_barra "$ram_porc"
    echo -e "              (Usada: ${ram_used}MB / Total: ${ram_total}MB)"

    # Swap Usage
    read swap_total swap_used < <(free -m | awk 'NR==3{print $2, $3}')
    if [ "$swap_total" -gt 0 ]; then
        swap_porc=$((swap_used * 100 / swap_total))
    else
        swap_porc=0
    fi
    echo -n " SWAP Usada : "
    dibujar_barra "$swap_porc"
    echo -e "              (Usada: ${swap_used}MB / Total: ${swap_total}MB)"

    # SSD / Disco Principal Usado
    read ssd_total ssd_used ssd_porc < <(df / | awk 'NR==2{print $2, $3, $5}' | tr -d '%')
    ssd_used_gb=$((ssd_used / 1024 / 1024))
    ssd_total_gb=$((ssd_total / 1024 / 1024))
    echo -n " SSD ( / )  : "
    dibujar_barra "$ssd_porc"
    echo -e "              (Usada: ${ssd_used_gb}GB / Total: ${ssd_total_gb}GB)"

    echo -e "\e[1;36m---------------------------------------------------------------------------------\e[0m"

    # --- 2. CONTENEDORES DOCKER LEVANTADOS ---
    echo -e "\e[1;34m[ CONTENEDORES DOCKER ACTIVOS ]\e[0m"

    if ! command -v docker &> /dev/null || ! docker info &> /dev/null; then
        echo -e "\e[31m  [!] Docker no está instalado o no se puede conectar al daemon.\e[0m"
    else
        # Cabecera de la tabla sin puertos
        printf "\e[1;37m%-35s | %-25s\e[0m\n" "NOMBRE" "IP"
        echo "---------------------------------------------------------------------------------"

        containers=$(docker ps --format "{{.ID}}")

        if [ -z "$containers" ]; then
            echo -e "  \e[33mNo hay contenedores activos en este momento.\e[0m"
        else
            for cid in $containers; do
                c_name=$(docker inspect -f '{{.Name}}' "$cid" | sed 's/\///')

                # Obtener IP del contenedor
                c_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "$cid" | xargs)
                [ -z "$c_ip" ] && c_ip="Bridge/Host"

                # Imprimir fila optimizada sin puertos
                printf "\e[32m%-35s\e[0m | \e[36m%-25s\e[0m\n" "$c_name" "$c_ip"
            done
        fi
    fi

    echo -e "\e[1;36m=================================================================================\e[0m"
    echo -e " \e[90mActualizando cada ${REFRESCO}s. Presiona [CTRL + C] para salir.\e[0m"

    # Pausa de 20 segundos antes del siguiente ciclo
    sleep "$REFRESCO"
    clear
done