#!/bin/bash
set -e

echo "[ ****************** ] Starting Endpoint of Application"
if ! [ -d "/var/www/html/glpi/vendor" ]; then
    echo "Application not found in /var/www/html/glpi - Downloading now..."
    if [ "$(ls -A)" ]; then
        echo "WARNING: /var/www/html/glpi is not empty - press Ctrl+C now if this is an error!"
        ( set -x; ls -A; sleep 10 )
    fi
    echo "[ ****************** ] Execute download of the GLPI"
    cd /tmp
    wget https://github.com/glpi-project/glpi/releases/download/9.5.6/glpi-9.5.6.tgz

    echo "[ ****************** ] Extract GLPI Application"
    tar -xvzf glpi-9.5.6.tgz

    echo "[ ****************** ] Copying sample application configuration to real one"
    mv glpi glpi
    cp -av /tmp/glpi /var/www/html/

    ls -la /var/www/html/glpi

    echo "[ ****************** ] Changing owner and group from the Project to 'www-data' "
    chown www-data:www-data -R /var/www/html/glpi
    chmod 775 /var/www/html -Rf

    echo "[ ****************** ] Enter in the directory of the application and clone the code of the 'vendor' project"
    cd /var/www/html/glpi

fi

echo "[ ****************** ] Ending Endpoint of Application"
exec "$@"
