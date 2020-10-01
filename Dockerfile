#
# Autor: Andressa Gomes (andressa.gomes@jbtec.com.br)
# Data : 2019-09-24
#

FROM debian:9.0

LABEL maintainer="Andressa Gomes (andressa.gomes@jbtec.com.br)"

VOLUME /var/www

RUN useradd -d /etc/asterisk --system asterisk

RUN apt-get update -y && \
    apt-get install -y build-essential \
    libjansson-dev libxml2-dev \
    libncurses5-dev uuid-dev \
    pkg-config wget netcat sox \
    gettext-base subversion \
    libedit-dev libxml2-dev \
    uuid procps libsqlite3-dev \
    apache2 git php php-curl libopus-dev \
    php-cli php-pdo php-mysql php-mbstring \
    php-pear php-gd curl cron libssl-dev sox \
    portaudio19-dev xmlstarlet

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - 

RUN apt-get install -y nodejs

RUN cd /usr/src && \
    wget "http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz" && \
    tar xvfz asterisk-16-current.tar.gz && \
    rm -f asterisk-16-current.tar.gz && \
    cd asterisk-16* && \
    contrib/scripts/install_prereq install-unpackaged && \
    ./configure --with-pjproject-bundled --with-jansson-bundled && \
    contrib/scripts/get_mp3_source.sh && \
    make menuselect.makeopts && \
    menuselect/menuselect --enable app_macro --enable format_mp3 menuselect.makeopts && \
    make && \
    make install && \
    make samples && \
    make config && \
    ldconfig && \
    make install-logrotate

RUN mkdir -p /usr/src/codecs/opus && \
    cd /usr/src/codecs/opus && \
    curl -vsL http://downloads.digium.com/pub/telephony/codec_opus/asterisk-16.0/x86-64/codec_opus-16.0_1.3.0-x86_64.tar.gz | tar --strip-components 1 -xz && \
    cp *.so /usr/lib/asterisk/modules/  && \
    cp codec_opus_config-en_US.xml /var/lib/asterisk/documentation/

RUN cd /usr/src && \
    git clone -b release/15.0 https://github.com/FreePBX/framework.git freepbx

RUN chown asterisk. /var/run/asterisk 
RUN chown -R asterisk. /etc/asterisk 
RUN chown -R asterisk. /var/log/asterisk
RUN chown -R asterisk. /var/spool/asterisk
RUN chown -R asterisk. /var/lib/asterisk
RUN chown -R asterisk. /usr/lib/asterisk
RUN rm -rf /var/www/html

RUN sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php/7.0/apache2/php.ini 
RUN cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf_orig 
RUN sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf 
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf 
RUN a2enmod rewrite

RUN touch /etc/asterisk/{modules,cdr}.conf

# Configurações dos Ambientes Asterisk e FreePBX

COPY configs/manager.conf.template /etc/asterisk

COPY entrypoint.sh /

RUN chmod 760 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD [ "server" ]