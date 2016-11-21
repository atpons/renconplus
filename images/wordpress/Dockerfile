FROM ubuntu:latest
MAINTAINER atpons
RUN apt-get update
RUN apt-get -y install vim curl git
RUN apt-get -y install apache2
RUN echo "mysql-server mysql-server/root_password password root" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections && \
    apt-get -y install mysql-server
RUN service mysql restart && echo "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;" | mysql -uroot -proot
RUN apt-get -y install php libapache2-mod-php php-mysql
RUN service apache2 restart
RUN echo "<Directory /var/www/html/wordpress>" >> /etc/apache2/apache2.conf
RUN echo "AllowOverride All" >> /etc/apache2/apache2.conf
RUN echo "</Directory>" >> /etc/apache2/apache2.conf
RUN cd && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp
RUN wp --allow-root core download --locale=ja --path=/tmp/wordpress
RUN touch /tmp/wordpress/.htaccess && chmod 660 /tmp/wordpress/.htaccess
RUN cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php && mkdir /tmp/wordpress/wp-content/upgrade && cp -a /tmp/wordpress/. /var/www/html/wordpress && chown -R root:www-data /var/www/html/wordpress && chmod g+w /var/www/html/wordpress/wp-content && chmod -R g+w /var/www/html/wordpress/wp-content/themes && chmod -R g+w /var/www/html/wordpress/wp-content/plugins

RUN sed /var/www/html/wordpress/wp-config.php -e " \
  /^define('DB_NAME'/c     define('DB_NAME', 'wordpress'); \
  /^define('DB_USER'/c     define('DB_USER', 'root'); \
  /^define('DB_PASSWORD'/c define('DB_PASSWORD', 'root'); \
" -i

RUN curl https://api.wordpress.org/secret-key/1.1/salt/ > /tmp/secret

RUN sed /var/www/html/wordpress/wp-config.php -e " \
  /^define('AUTH_KEY'/r /tmp/secret \
  /^define('AUTH_KEY'/d \
  /^define('SECURE_AUTH_KEY'/d \
  /^define('LOGGED_IN_KEY'/d \
  /^define('NONCE_KEY'/d \
  /^define('AUTH_SALT'/d \
  /^define('SECURE_AUTH_SALT'/d \
  /^define('LOGGED_IN_SALT'/d \
  /^define('NONCE_SALT'/d \
" -i

RUN cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/010-wordpress.conf

RUN sed -i -e "12 s/html/html\/wordpress/g" /etc/apache2/sites-available/010-wordpress.conf
RUN a2dissite 000-default
RUN a2ensite 010-wordpress
RUN cat /etc/apache2/apache2.conf
RUN service apache2 restart
RUN cd && echo "service mysql restart" >> run.sh && echo "service apache2 restart" >> run.sh
RUN cd && chmod 777 run.sh && cat run.sh
