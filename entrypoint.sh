#!/bin/bash

function waitPort() {
    # Determina as variaveis
    host=$1
    port=$2
    msg=$3

    # Inicia o looping para aguardar
    start_ts=$(date +%s)
    while :
    do
      nc -w 1 -z $host $port 2>/dev/null
      result=$?
      end_ts=$(date +%s)
      if [[ $result -eq 0 ]]; then
        break
      else
        echo "$msg - $((end_ts - start_ts)) segundos..."
      fi
      sleep 1
    done
}

waitPort $ASTERISK_DB_HOST $ASTERISK_DB_PORT "Aguardando servidor: $ASTERISK_DB_ENGINE"


if [ ! -f /freepbx.installed ] ; then
    touch /freepbx.installed
    bash /usr/src/freepbx/start_asterisk start
    cd /usr/src/freepbx && \
      /usr/bin/php /usr/src/freepbx/install --dbengine=$ASTERISK_DB_ENGINE --dbname=$ASTERISK_DB_NAME --dbhost=$ASTERISK_DB_HOST --dbuser=$ASTERISK_DB_USER --dbpass=$ASTERISK_DB_PASSWORD -n
    fwconsole moduleadmin installall
    chown -R asterisk:asterisk /var/www
fi

cat /etc/asterisk/manager.conf.template | envsubst > /etc/asterisk/manager.conf

if [ "$1" == "server" ] ; then
    echo "Starting Asterisk Services"
    /usr/sbin/apache2ctl -D FOREGROUND
    tail -f /dev/null
else
    $@
fi