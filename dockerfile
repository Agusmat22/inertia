# Etapa 1: Construcción del backend de Laravel
FROM php:8.2-fpm AS backend

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    unzip \
    git \
    curl \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    zip \
    && docker-php-ext-configure gd \
    && docker-php-ext-install gd pdo pdo_mysql zip

# Instalar Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Crear usuario para la aplicación
RUN useradd -m laravel
WORKDIR /var/www/html

# Copiar el código de Laravel al contenedor
COPY . .

# Instalar dependencias de Laravel
RUN composer install --no-dev --optimize-autoloader

# Permisos para Laravel
RUN chown -R laravel:laravel /var/www/html
USER laravel

# Etapa 2: Construcción del frontend con React + Vite
FROM node:18 AS frontend
WORKDIR /app

# Copiar archivos necesarios para instalar dependencias
COPY package.json package-lock.json /app/

# Instalar dependencias de frontend
RUN npm install

# Copiar el código del frontend y compilar con Vite
COPY . /app
RUN npm run build

# Etapa 3: Contenedor final con Nginx para servir la SPA
FROM nginx

# Copiar configuración de Nginx
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Copiar el backend de Laravel
COPY --from=backend /var/www/html /var/www/html

# Copiar los archivos compilados de React (Vite)
COPY --from=frontend /app/public /var/www/html/public

# Configurar permisos para Nginx
RUN chown -R www-data:www-data /var/www/html

# Exponer el puerto 80
EXPOSE 80

# Comando de inicio
CMD ["nginx", "-g", "daemon off;"]
