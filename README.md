# backup_sqlserver

Este script en bash realiza respaldos automáticos de bases de datos SQL Server. Se conecta a un servidor SQL Server utilizando "sqlcmd", obtiene la lista de bases de datos disponibles (excluyendo las bases de datos del sistema y "tempdb"), y luego realiza respaldos completos de cada una de las bases de datos encontradas. Finalmente, borra los archivos de backups antiguos con 2 o más días de antigüedad.

Descripción detallada paso a paso:

Se establecen las variables necesarias para configurar la ubicación del directorio de backups (backup_dir), el nombre de usuario (db_user) y contraseña (db_password) para la conexión al servidor SQL Server, así como el host (db_host) y puerto (db_port) del servidor. El formato de fecha y hora actual se obtiene y almacena en la variable current_datetime.

Se crea el directorio de backups y el directorio para el archivo de log si no existen utilizando el comando mkdir -p.

Se define la función log_message para registrar mensajes en el archivo de log (backup_sqlserver.log) con fecha y hora. Los mensajes se agregan al archivo utilizando el comando echo junto con la redirección >> para añadir al archivo sin sobrescribir el contenido anterior.

Se registra el inicio del script en el archivo de log utilizando log_message.

Se utiliza "sqlcmd" para obtener la lista de bases de datos disponibles en el servidor SQL Server, excluyendo las bases de datos del sistema y "tempdb". La consulta SQL utilizada es: SELECT name FROM sys.databases WHERE database_id > 4 AND state_desc = 'ONLINE'. La salida se almacena en la variable database_list.

Se verifica si se encontraron bases de datos válidas en database_list. Si no se encuentran bases de datos válidas, se registra un mensaje en el archivo de log y el script se detiene con un código de salida 1.

Se convierte la lista de bases de datos en un array llamado databases utilizando el comando readarray. Esto facilita el proceso de iterar sobre cada base de datos encontrada.

Se inicia un bucle for para iterar a través de cada base de datos en el array databases.

Se define el nombre del archivo de backup utilizando el nombre de la base de datos, la cadena "-PROD-" y la fecha y hora actual. El archivo de backup tendrá una extensión .bak.

Se registra la hora de inicio del backup en el archivo de log utilizando log_message.

Se ejecuta el comando sqlcmd para realizar el respaldo de la base de datos actual. El comando ejecutado es: sqlcmd -S "$db_host,$db_port" -U "$db_user" -P "$db_password" -Q "BACKUP DATABASE [$db_name] TO DISK = N'$backup_file' WITH NOFORMAT, INIT, NAME = '$db_name-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10". Este comando realiza un respaldo completo de la base de datos actual y lo guarda en el archivo de backup definido.

Se verifica si el respaldo se completó correctamente utilizando $?, que almacena el código de salida del comando anterior. Si el código de salida es 0, el respaldo se considera exitoso y se registra la hora de finalización del backup en el archivo de log, junto con el tamaño del archivo de backup.

Si el respaldo falla (código de salida diferente de 0), se registra un mensaje de error en el archivo de log.

El bucle for continúa con la siguiente base de datos en la lista.

Una vez que se han respaldado todas las bases de datos, se procede a buscar y borrar archivos de backups antiguos con 2 o más días de antigüedad en el directorio backup_dir. Esto se hace utilizando el comando find con las opciones -type f -name "*.bak" -mtime +1 -print -delete, que encuentra los archivos con extensión .bak que tienen 2 o más días de antigüedad y los borra.

Finalmente, se registra el fin del script en el archivo de log utilizando log_message. El script ha terminado.