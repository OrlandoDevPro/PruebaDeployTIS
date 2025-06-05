#!/bin/bash
set -e

echo "🚀 Iniciando configuración de producción..."

# Esperar a que la base de datos esté disponible
echo "⏳ Esperando conexión a la base de datos..."
START_TIME=$(date +%s)
TIMEOUT=60
while ! php artisan migrate:status 2>/dev/null; do
    echo "⏳ Esperando conexión a BD..."
    sleep 3
    CURRENT_TIME=$(date +%s)
    if (( CURRENT_TIME - START_TIME > TIMEOUT )); then
        echo "❌ Timeout en la conexión a la BD"
        exit 1
    fi
done

echo "✅ Base de datos conectada exitosamente"

# Limpiar cache antes de empezar
echo "🧹 Limpiando cache existente..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan cache:clear

# Ejecutar migrate:fresh con seeders (borra todo y recrea limpio)
echo "🗑️ Eliminando tablas existentes y recreando con seeders..."
php artisan migrate:fresh --seed --force

# Crear enlace simbólico para storage
echo "🔗 Creando enlace simbólico para storage..."
php artisan storage:link

# Optimizaciones para producción
echo "⚡ Aplicando optimizaciones de producción..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Asegurar permisos correctos
echo "🔒 Configurando permisos..."
chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
chmod -R 775 /var/www/storage /var/www/bootstrap/cache

echo "🌐 Iniciando PHP-FPM..."
php-fpm &

# Esperar a que PHP-FPM esté listo
echo "⏳ Esperando que PHP-FPM esté listo..."
while ! nc -z localhost 9000; do
  sleep 1
done
echo "✅ PHP-FPM está listo"

echo "🚀 Iniciando Nginx..."
nginx -g "daemon off;" &

# Verificar que Nginx esté escuchando en el puerto correcto
echo "⏳ Esperando que Nginx esté listo..."
while ! nc -z localhost ${PORT:-8080}; do
  sleep 1
done
echo "✅ Nginx está escuchando en puerto ${PORT:-8080}"

# Mantener el contenedor activo
tail -f /dev/null