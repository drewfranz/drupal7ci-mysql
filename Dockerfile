FROM juampynr/drupal7ci:php-7.3

# Install mysql 5.7.
RUN apt update && apt install -y lsb-release gnupg wget debconf-utils \
    && echo 'f6a7c41f04cc4fea7ade285092eea77a  mysql-apt-config_0.8.16-1_all.deb' > mysql-apt-config_0.8.16-1_all.deb.md5 \
    && wget https://dev.mysql.com/get/mysql-apt-config_0.8.16-1_all.deb \
    && md5sum -c mysql-apt-config_0.8.16-1_all.deb.md5 \
    && echo 'mysql-apt-config mysql-apt-config/repo-distro select debian'      | debconf-set-selections \
    && echo 'mysql-apt-config mysql-apt-config/select-server select mysql-5.7' | debconf-set-selections \
    && DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.16-1_all.deb \
    && apt update \
    && DEBIAN_FRONTEND=noninteractive apt install -y mysql-community-client mysql-client mysql-community-server mysql-server

# Create the default user and database.
RUN service mysql start \
    && echo "CREATE DATABASE IF NOT EXISTS drupal CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci ;"   | mysql -uroot \
    && echo "CREATE USER 'drupal'@'%' IDENTIFIED BY 'drupal' ;"                                         | mysql -uroot \
    && echo "GRANT ALL ON drupal.* TO 'drupal'@'%' WITH GRANT OPTION ;"                                 | mysql -uroot \
    && echo "FLUSH PRIVILEGES ;"                                                                        | mysql -uroot \
    && service mysql stop

# Install additional dependencies.
RUN printf "#### Install PHP Extensions ####\n" \
    && apt update \
    && apt install -y libzip-dev tini \
    && docker-php-ext-install gettext zip \
        \
    && printf "\n#### Install Composer 1.x ####\n" \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --1 \
        \
    && printf "\n#### Install Composer Global Require ####\n" \
    && composer global require consolidation/cgr \
    && PATH="$(composer config -g home)/vendor/bin:$PATH" \
        \
    && printf "\n#### Disabling XDebug ####\n" \
    && sed -i -e 's/zend_extension/\;zend_extension/g' $(php --info | grep xdebug.ini | sed 's/,*$//g') \
        \
    && printf "\n#### Set up Apache ####\n" \
    && sudo -u www-data mkdir -p /var/www/html/docroot \
    && sudo -u www-data touch /var/www/html/docroot/index.html

# Copy the init file.
COPY docker-init /usr/local/bin/

# Expose the default apace2 and mysql ports.
EXPOSE 80 3306

# Setup the healthcheck command
HEALTHCHECK CMD /usr/bin/mysqladmin ping && /usr/bin/curl --fail http://localhost || exit 1

# Let tini manage daemons.
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/docker-init"]
