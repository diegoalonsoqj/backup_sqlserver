#!/bin/bash

# Directorio de almacenamiento de backups
backup_dir="/backups/sqlserver"

# Nombre de usuario y contraseña de SQL Server
db_user="tu_usuario"
db_password="tu_contraseña"

# Host y puerto del servidor SQL Server
db_host="localhost"
db_port="1433"  # Cambiar al puerto correcto si SQL Server usa uno diferente al puerto predeterminado (1433).

# Obtener la fecha y hora actual
current_datetime=$(date +"%Y%m%d_%H%M")

# Crear el directorio de backups si no existe
mkdir -p "$backup_dir"

# Directorio para guardar el archivo de log
log_dir="/var/log/scripts"
mkdir -p "$log_dir"

# Archivo de log
log_file="$log_dir/backup_sqlserver.log"

# Función para registrar mensajes en el archivo de log con fecha y hora
function log_message {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$log_file"
}

# Inicio del script
log_message "Inicio del script de backup de bases de datos SQL Server."

# Obtener la lista de bases de datos existentes, excluyendo las bases de datos del sistema y tempdb
database_list=$(sqlcmd -S "$db_host,$db_port" -U "$db_user" -P "$db_password" -Q "SELECT name FROM sys.databases WHERE database_id > 4 AND state_desc = 'ONLINE'" | grep -oE '[^\ ]+$')

# Verificar si se encontraron bases de datos válidas
if [ -z "$database_list" ]; then
    log_message "No se encontraron bases de datos válidas para respaldar. Saliendo del script."
    exit 1
fi

# Convertir la lista de bases de datos en un array
readarray -t databases <<< "$database_list"

# Iterar a través de cada base de datos y realizar el respaldo
for db_name in "${databases[@]}"
do
    # Nombre del archivo de backup
    backup_file="$backup_dir/${db_name}-PROD-${current_datetime}.bak"

    # Registro de hora de inicio del backup
    log_message "Inicio del backup de la base de datos $db_name."

    # Realizar el respaldo utilizando sqlcmd
    echo "Ejecutando comando sqlcmd para respaldar la base de datos $db_name..."
    sqlcmd -S "$db_host,$db_port" -U "$db_user" -P "$db_password" -Q "BACKUP DATABASE [$db_name] TO DISK = N'$backup_file' WITH NOFORMAT, INIT, NAME = '$db_name-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

    # Verificar si el respaldo se completó correctamente
    if [ $? -eq 0 ]; then
        # Registro de hora de finalización del backup
        log_message "Backup de $db_name completado: $backup_file"

        # Obtener el peso del backup generado
        backup_size=$(du -h "$backup_file" | cut -f 1)
        log_message "Peso del backup: $backup_size"
    else
        log_message "ERROR: Fallo al respaldar $db_name"
    fi
done

# Borrar archivos con 2 o más días de antigüedad
log_message "Buscando y borrando archivos de backups con 2 o más días de antigüedad..."
find "$backup_dir" -type f -name "*.bak" -mtime +1 -print -delete >> "$log_file" 2>&1

# Finalización del script
log_message "Fin del script de backup de bases de datos SQL Server."
