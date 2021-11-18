FROM php:7.1.17-apache-jessie

VOLUME ["/var/www/html"]

RUN echo "[ ***** ***** ***** ] - Copying files to Image ***** ***** ***** "

USER root

#Copiando os arquivos do HOST para a IMAGEM
COPY ./src /tmp/src
#RUN cp -av /tmp/src/actions/yum/sources.list /etc/apt/

RUN yum update

RUN echo "[ ***** ***** ***** ] - Installing each item in new command to use cache and avoid download again ***** ***** ***** "
RUN yum install -y apt-utils
RUN yum install -y libfreetype6-dev
RUN yum install -y libjpeg62-turbo-dev
RUN yum install -y libcurl4-gnutls-dev
RUN yum install -y libxml2-dev
RUN yum install -y freetds-dev
RUN yum install -y git
RUN yum install -y wget
RUN yum install -y mysql-client

# LDAP requirements
RUN yum install libldap2-dev -y && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu && \
    docker-php-ext-install -j$(nproc) ldap

# IMAP requirements
RUN yum install -y openssl
RUN yum install -y libc-client2007e-dev
RUN yum install -y libkrb5-dev

RUN yum install libldap2-dev -y && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-install -j$(nproc) imap

# BCMath is needed on Scleroseforeningen D8
RUN docker-php-ext-install -j$(nproc) bcmath && \
    docker-php-ext-enable bcmath

#vim is usefull for debug container in interactive shell
RUN yum install -y vim
RUN yum install -y telnet
RUN yum install -y zip
RUN yum install -y unzip
RUN yum install -y bzip2
RUN yum install -y unrar-free
RUN yum install -y ca-certificates

RUN echo "[ ***** ***** ***** ] - Installing PHP Dependencies ***** ***** ***** "

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install gd
RUN docker-php-ext-install soap

# opcache
RUN yum update && yum install -y zlib1g-dev libicu-dev libpq-dev \
    && docker-php-ext-install opcache \
    && docker-php-ext-install intl \
    && docker-php-ext-install mbstring \
#    && docker-php-ext-install pdo_mysql \
#    && docker-php-ext-install pdo_pgsql \
    ## APCu
    && pecl install apcu-5.1.5 \
    && docker-php-ext-enable apcu

# Install xmlrpc
RUN docker-php-ext-install xmlrpc

RUN docker-php-ext-install calendar
RUN yum update && yum install -y libpq-dev && docker-php-ext-install pdo

#Configurando extenções especificas do Mysql
RUN docker-php-ext-configure mysqli --with-libdir=/lib/x86_64-linux-gnu && docker-php-ext-install mysqli
RUN docker-php-ext-configure pdo_mysql --with-libdir=/lib/x86_64-linux-gnu && docker-php-ext-install pdo_mysql

RUN chmod +x -R /tmp/src/

#Atualiza os pacotes da imagem
RUN yum upgrade -y

# Cleanup all downloaded packages
RUN yum -y autoclean && yum -y autoremove && yum -y clean && rm -rf /var/lib/apt/lists/* && yum update

#Similar ao comando CD do terminal. Permite setar o diretório que o trabalho ocorrerá (Na Imagem).
WORKDIR /var/www/html/

EXPOSE 80
EXPOSE 443
EXPOSE 8888

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

RUN echo "[ Step 03 ] - Begin of Actions inside Image ***** ***** ***** "

RUN echo "[ Step 03.01 ] - Insert  ***** ***** ***** "
RUN echo "127.0.0.1     dev.glpi.com.br" >> /etc/hosts

RUN echo "[******] Copying and enable virtualhost 'site.conf'";
COPY ./src/actions/apache2/sites-available/site.conf /etc/apache2/sites-available/site.conf
RUN echo "[******] Copying and enable virtualhost 'status.conf'";
COPY ./src/actions/apache2/sites-available/status.conf /etc/apache2/sites-available/status.conf

RUN echo "[******] Copying configurations for security of apache.";
COPY ./src/actions/apache2/conf-available/security.conf /etc/apache2/conf-available/security.conf

RUN echo "[******] Copying configurations for security of apache.";
COPY ./src/actions/apache2/ports.conf /etc/apache2/ports.conf

RUN echo "[******] Copying configurations for apache2.";
COPY ./src/actions/apache2/apache2.conf /etc/apache2/apache2.conf

RUN echo "[******] Enable the enviroments variables.";
#RUN . /etc/apache2/envvars
#RUN apache2 -V

#RUN echo "[******] Reload Apache 2 Service Configs. #1";
#service apache2 reload


RUN echo "[******] Enable modules necessary";
RUN a2ensite site.conf
RUN a2ensite status.conf

RUN echo "[******] Disable default virtualhost '000-default.conf'";
RUN a2dissite 000-default.conf

RUN echo "[******] Enable Apache Mod Rewrite";
RUN a2enmod rewrite

RUN echo "[******] Enable Apache Mod Headers";
RUN a2enmod headers

#RUN echo "[******] Reload Apache 2 Service Configs. #2";
#service apache2 reload

RUN echo "[******] Starts Apache using Foreground Mode";
# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

RUN echo "[******] Descobrindo o usuario Logado";
RUN whoami


CMD ["/usr/sbin/apache2", "-D", "FOREGROUND"]
#CMD /usr/sbin/apache2ctl -D FOREGROUND



#CMD /tmp/src/actions/start.sh

