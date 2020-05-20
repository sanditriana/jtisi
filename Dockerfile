FROM alpine
LABEL Maintainer="sandi triana" \
      Description="fintren API with Nginx 1.16 & PHP-FPM 7.3 based on Alpine Linux."

# Install packages
RUN apk --no-cache add php7 php7-fpm php7-opcache php7-mysqli php7-json php7-openssl php7-curl \
    php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-ctype php7-session \
    php7-mbstring php7-gd nginx supervisor curl php7-xmlwriter php7-tokenizer php7-pdo php7-pdo_mysql

# Configure nginx
COPY deployment/nginx.conf /etc/nginx/nginx.conf
# Remove default server definition
RUN rm /etc/nginx/conf.d/default.conf

# Configure PHP-FPM
COPY deployment/custom-pool.conf /etc/php7/php-fpm.d/www.conf
COPY deployment/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY deployment/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Setup document root
RUN mkdir -p /var/www/html

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
#RUN chown -R root.root /var/www/html && \
#  chown -R root.root /run && \
#  chown -R root.root /var/lib/nginx && \
#  chown -R root.root /var/log/nginx


# Switch to use a non-root user from here on
#USER nobody

# Add application
WORKDIR /var/www/html
#COPY --chown=nobody ./ /var/www/html/
COPY ./ /var/www/html/

RUN chmod -R 777 storage/
RUN chmod -R 777 bootstrap/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
# HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping