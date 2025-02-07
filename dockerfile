##############################
# Stage 1: Construir el backend de Laravel
##############################
FROM php:8.2-fpm AS backend

# Instalar dependencias del sistema y extensiones PHP necesarias
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    curl

# Instalar extensiones PHP
RUN docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd

# Instalar Composer desde la imagen oficial de Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Establecer directorio de trabajo
WORKDIR /var/www

# Copiar archivos mínimos necesarios: composer.json, composer.lock, artisan,
# el directorio bootstrap (que contiene app.php) y routes
COPY composer.json composer.lock artisan ./
COPY bootstrap ./bootstrap
COPY routes ./routes

# Ejecutar composer install para generar la carpeta vendor
# (la salida de ls servirá para confirmar que vendor se generó correctamente)
RUN composer install --no-dev --optimize-autoloader && \
    echo "Contenido de /var/www/vendor:" && ls -la /var/www/vendor

# Copiar el resto del código de la aplicación
# Gracias a .dockerignore (que debe contener "vendor"), no se sobrescribe la carpeta vendor generada
COPY . .

# Ajustar permisos para storage y bootstrap/cache
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

##############################
# Stage 2: Construir el frontend con React e Inertia (Vite)
##############################
FROM node:18 AS frontend

WORKDIR /app

# Copiar archivos de Node y instalar dependencias
COPY package.json package-lock.json ./
RUN npm install

# Copiar el resto del código y compilar los assets
COPY . .
RUN npm run build

##############################
# Stage 3: Imagen final combinada (PHP-FPM + assets compilados)
##############################
FROM php:8.2-fpm

# Instalar dependencias y extensiones PHP en tiempo de ejecución
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip && \
    docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd

WORKDIR /var/www

# Copiar el backend completo (incluye vendor generado) desde la etapa 1
COPY --from=backend /var/www .

# Copiar los assets compilados desde la etapa 2 (normalmente generados en /app/public/build)
COPY --from=frontend /app/public/build ./public/build

# Ajustar permisos para que PHP-FPM pueda acceder a todos los archivos
RUN chown -R www-data:www-data /var/www

EXPOSE 9000

CMD ["php-fpm"]
