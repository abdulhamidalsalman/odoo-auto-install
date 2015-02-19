#!/bin/bash
################################################################################
# Script for Installation: ODOO Saas4/Trunk server on Ubuntu 14.04 LTS
# Author: Andras Santoro
#-------------------------------------------------------------------------------
# This script will install ODOO Server on clean Ubuntu 14.xx Server
# - added Nginx Proxy Server
#-------------------------------------------------------------------------------
# EXAMPLE:
# - sudo ./install_odoo.sh
#-------------------------------------------------------------------------------
# TESTED ON:
# - Ubuntu 14.04 LTS
################################################################################

# Update and Upgrade the Ubuntu Server
ODOO_SERVER_UPGRADESERVER="false"

#--ODOO 
ODOO_GIT_VERSION="master" #The version from GITHUB to install "8.0" / "7.0" / "master" / "saas-4"...
ODOO_USER="odoo" #This is the user odoo is running under
ODOO_INSTALL_DIRECTORY="/opt/odoo/" #Install directory
ODOO_INSTALL_DIRECTORY_EXT="/opt/odoo/odoo-server"	#Install directory odoo server
ODOO_SERVER_ADMIN_PASSWORD="!superadmin123" #The admin password for odoo after installation
ODOO_CONFIGFILE_NAME="odoo-server" #The config file name "odoo-server.conf"

#--PostgresSQL
ODOO_SERVER_POSTGRES_INSTALL="true" #Install Postgress database server
ODOO_SERVER_POSTGRES_PASSWORD="$ODOO_SERVER_ADMIN_PASSWORD" #Database server password

#--NGINX
ODOO_SERVER_NGINX_INSTALL="true" #Install
ODOO_SERVER_NGINX_URL="odoo.mycompany.com"
ODOO_SERVER_NGINX_URL_PREFIX="https://"
ODOO_SERVER_NGINX_PORT="443"
ODOO_SERVER_NGINX_CONFIG_FILE="$ODOO_SERVER_NGINX_URL" #file name for config

# Check if run as sudo
if [ "$(id -u)" != "0" ]; then
	echo "******************************************************************"
	echo "	Installation of ODOO FAILED"
	echo "	please run with "
	echo "	sudo ./install_odoo.sh "
	echo "******************************************************************"
	exit 1
fi

#--------------------------------------------------
# Update Server
#--------------------------------------------------
if [ $ODOO_SERVER_UPGRADESERVER == "true" ]
then
	echo -e "\n---- Update Server ----"
	sudo apt-get update -y
	sudo apt-get upgrade -y
else
	echo -e "\n---- Server update skipped ----"
fi

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
if [ $ODOO_SERVER_POSTGRES_INSTALL == "true" ]
then
	echo -e "\n---- Install PostgreSQL server ----"
	sudo apt-get install postgresql -y
		
	echo -e "\n---- PostgreSQL $PG_VERSION Settings  ----"
	sudo sed -i s/"#listen_addresses = 'localhost'"/"listen_addresses = '*'"/g /etc/postgresql/9.3/main/postgresql.conf

	echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
	sudo su - postgres -c "createuser -s $ODOO_USER" 2> /dev/null || true

	#TODO: set postgres password
else
	echo -e "\n---- PostgreSQL skipped ----"
fi
#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
sudo apt-get install wget subversion git bzr bzrtools python-pip -y
	
echo -e "\n---- Install python packages ----"
sudo apt-get install python-dateutil python-feedparser python-ldap python-libxslt1 python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi python-docutils python-psutil python-mock python-unittest2 python-jinja2 python-pypdf -y
sudo apt-get install python-decorator python-passlib python-geoip python-requests -y
	
echo -e "\n---- Install python libraries ----"
sudo pip install gdata
	
echo -e "\n---- Create ODOO system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$ODOO_INSTALL_DIRECTORY --gecos 'ODOO' --group $ODOO_USER

echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$ODOO_USER
sudo chown $ODOO_USER:$ODOO_USER /var/log/$ODOO_USER

#--------------------------------------------------
# Install wkhtmltopdf PDF Engine
#--------------------------------------------------
# Todo: Something changed with the sources. 404 not found is returned
sudo wget http://downloads.sourceforge.net/project/wkhtmltopdf/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
sudo dpkg -i wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
# Todo: copy files to /usr/local/bin

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --branch $ODOO_GIT_VERSION https://www.github.com/odoo/odoo $ODOO_INSTALL_DIRECTORY_EXT/

echo -e "\n---- Create custom module directory ----"
sudo su $ODOO_USER -c "mkdir $ODOO_INSTALL_DIRECTORY/custom"
sudo su $ODOO_USER -c "mkdir $ODOO_INSTALL_DIRECTORY/custom/addons"

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $ODOO_USER:$ODOO_USER $ODOO_INSTALL_DIRECTORY/*

echo -e "\n---- Create server config file"
sudo cp $ODOO_INSTALL_DIRECTORY_EXT/debian/openerp-server.conf /etc/$ODOO_CONFIGFILE_NAME.conf
sudo chown $ODOO_USER:$ODOO_USER /etc/$ODOO_CONFIGFILE_NAME.conf
sudo chmod 640 /etc/$ODOO_CONFIGFILE_NAME.conf

echo -e "\n---- Change server config file"
sudo sed -i s/"db_user = .*"/"db_user = $ODOO_USER"/g /etc/$ODOO_CONFIGFILE_NAME.conf
sudo sed -i s/"; admin_passwd.*"/"admin_passwd = $ODOO_SERVER_ADMIN_PASSWORD"/g /etc/$ODOO_CONFIGFILE_NAME.conf
sudo su root -c "echo 'logfile = /var/log/$ODOO_USER/$ODOO_CONFIGFILE_NAME$1.log' >> /etc/$ODOO_CONFIGFILE_NAME.conf"
sudo su root -c "echo 'addons_path=$ODOO_INSTALL_DIRECTORY_EXT/addons,$ODOO_INSTALL_DIRECTORY/custom/addons' >> /etc/$ODOO_CONFIGFILE_NAME.conf"

echo -e "\n---- Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $ODOO_INSTALL_DIRECTORY_EXT/start.sh"
sudo su root -c "echo 'sudo -u $ODOO_USER $ODOO_INSTALL_DIRECTORY_EXT/openerp-server --config=/etc/$ODOO_CONFIGFILE_NAME.conf' >> $ODOO_INSTALL_DIRECTORY_EXT/start.sh"
sudo chmod 755 $ODOO_INSTALL_DIRECTORY_EXT/start.sh

#--------------------------------------------------
# ODOO Daemon
#--------------------------------------------------
echo -e "* Create init file"
echo '#!/bin/sh' >> ~/$ODOO_CONFIGFILE_NAME
echo '### BEGIN INIT INFO' >> ~/$ODOO_CONFIGFILE_NAME
echo '# Provides: $ODOO_CONFIGFILE_NAME' >> ~/$ODOO_CONFIGFILE_NAME
echo '# Required-Start: $remote_fs $syslog' >> ~/$ODOO_CONFIGFILE_NAME
echo '# Required-Stop: $remote_fs $syslog' >> ~/$ODOO_CONFIGFILE_NAME
echo '# Should-Start: $network' >> ~/$ODOO_CONFIGFILE_NAME
echo '# Should-Stop: $network' >> ~/$ODOO_CONFIGFILE_NAME
echo '# Default-Start: 2 3 4 5' >> ~/$ODOO_CONFIGFILE_NAME
echo '# Default-Stop: 0 1 6' >> ~/$ODOO_CONFIGFILE_NAME
echo '# Short-Description: Enterprise Business Applications' >> ~/$ODOO_CONFIGFILE_NAME
echo '# Description: ODOO Business Applications' >> ~/$ODOO_CONFIGFILE_NAME
echo '### END INIT INFO' >> ~/$ODOO_CONFIGFILE_NAME
echo 'PATH=/bin:/sbin:/usr/bin:/usr/local/bin/' >> ~/$ODOO_CONFIGFILE_NAME
echo "DAEMON=$ODOO_INSTALL_DIRECTORY_EXT/openerp-server" >> ~/$ODOO_CONFIGFILE_NAME
echo "NAME=$ODOO_CONFIGFILE_NAME" >> ~/$ODOO_CONFIGFILE_NAME
echo "DESC=$ODOO_CONFIGFILE_NAME" >> ~/$ODOO_CONFIGFILE_NAME
echo '' >> ~/$ODOO_CONFIGFILE_NAME
echo '# Specify the user name (Default: odoo).' >> ~/$ODOO_CONFIGFILE_NAME
echo "USER=$ODOO_USER" >> ~/$ODOO_CONFIGFILE_NAME
echo '' >> ~/$ODOO_CONFIGFILE_NAME
echo '# Specify an alternate config file (Default: /etc/openerp-server.conf).' >> ~/$ODOO_CONFIGFILE_NAME
echo "CONFIGFILE=\"/etc/$ODOO_CONFIGFILE_NAME.conf\"" >> ~/$ODOO_CONFIGFILE_NAME
echo '' >> ~/$ODOO_CONFIGFILE_NAME
echo '# pidfile' >> ~/$ODOO_CONFIGFILE_NAME
echo 'PIDFILE=/var/run/$NAME.pid' >> ~/$ODOO_CONFIGFILE_NAME
echo '' >> ~/$ODOO_CONFIGFILE_NAME
echo '# Additional options that are passed to the Daemon.' >> ~/$ODOO_CONFIGFILE_NAME
echo 'DAEMON_OPTS="-c $CONFIGFILE"' >> ~/$ODOO_CONFIGFILE_NAME
echo '[ -x $DAEMON ] || exit 0' >> ~/$ODOO_CONFIGFILE_NAME
echo '[ -f $CONFIGFILE ] || exit 0' >> ~/$ODOO_CONFIGFILE_NAME
echo 'checkpid() {' >> ~/$ODOO_CONFIGFILE_NAME
echo '[ -f $PIDFILE ] || return 1' >> ~/$ODOO_CONFIGFILE_NAME
echo 'pid=`cat $PIDFILE`' >> ~/$ODOO_CONFIGFILE_NAME
echo '[ -d /proc/$pid ] && return 0' >> ~/$ODOO_CONFIGFILE_NAME
echo 'return 1' >> ~/$ODOO_CONFIGFILE_NAME
echo '}' >> ~/$ODOO_CONFIGFILE_NAME
echo '' >> ~/$ODOO_CONFIGFILE_NAME
echo 'case "${1}" in' >> ~/$ODOO_CONFIGFILE_NAME
echo 'start)' >> ~/$ODOO_CONFIGFILE_NAME
echo 'echo -n "Starting ${DESC}: "' >> ~/$ODOO_CONFIGFILE_NAME
echo 'start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> ~/$ODOO_CONFIGFILE_NAME
echo '--chuid ${USER} --background --make-pidfile \' >> ~/$ODOO_CONFIGFILE_NAME
echo '--exec ${DAEMON} -- ${DAEMON_OPTS}' >> ~/$ODOO_CONFIGFILE_NAME
echo 'echo "${NAME}."' >> ~/$ODOO_CONFIGFILE_NAME
echo ';;' >> ~/$ODOO_CONFIGFILE_NAME
echo 'stop)' >> ~/$ODOO_CONFIGFILE_NAME
echo 'echo -n "Stopping ${DESC}: "' >> ~/$ODOO_CONFIGFILE_NAME
echo 'start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> ~/$ODOO_CONFIGFILE_NAME
echo '--oknodo' >> ~/$ODOO_CONFIGFILE_NAME
echo 'echo "${NAME}."' >> ~/$ODOO_CONFIGFILE_NAME
echo ';;' >> ~/$ODOO_CONFIGFILE_NAME
echo '' >> ~/$ODOO_CONFIGFILE_NAME
echo 'restart|force-reload)' >> ~/$ODOO_CONFIGFILE_NAME
echo 'echo -n "Restarting ${DESC}: "' >> ~/$ODOO_CONFIGFILE_NAME
echo 'start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \' >> ~/$ODOO_CONFIGFILE_NAME
echo '--oknodo' >> ~/$ODOO_CONFIGFILE_NAME
echo 'sleep 1' >> ~/$ODOO_CONFIGFILE_NAME
echo 'start-stop-daemon --start --quiet --pidfile ${PIDFILE} \' >> ~/$ODOO_CONFIGFILE_NAME
echo '--chuid ${USER} --background --make-pidfile \' >> ~/$ODOO_CONFIGFILE_NAME
echo '--exec ${DAEMON} -- ${DAEMON_OPTS}' >> ~/$ODOO_CONFIGFILE_NAME
echo 'echo "${NAME}."' >> ~/$ODOO_CONFIGFILE_NAME
echo ';;' >> ~/$ODOO_CONFIGFILE_NAME
echo '*)' >> ~/$ODOO_CONFIGFILE_NAME
echo 'N=/etc/init.d/${NAME}' >> ~/$ODOO_CONFIGFILE_NAME
echo 'echo "Usage: ${NAME} {start|stop|restart|force-reload}" >&2' >> ~/$ODOO_CONFIGFILE_NAME
echo 'exit 1' >> ~/$ODOO_CONFIGFILE_NAME
echo ';;' >> ~/$ODOO_CONFIGFILE_NAME
echo '' >> ~/$ODOO_CONFIGFILE_NAME
echo 'esac' >> ~/$ODOO_CONFIGFILE_NAME
echo 'exit 0' >> ~/$ODOO_CONFIGFILE_NAME

echo -e "\n---- Security File"
sudo mv ~/$ODOO_CONFIGFILE_NAME /etc/init.d/$ODOO_CONFIGFILE_NAME
sudo chmod 755 /etc/init.d/$ODOO_CONFIGFILE_NAME
sudo chown root: /etc/init.d/$ODOO_CONFIGFILE_NAME

echo -e "\n---- Start ODOO on Startup"
sudo update-rc.d $ODOO_CONFIGFILE_NAME defaults

#--------------------------------------------------
# Install NGINX reverse proxy
#--------------------------------------------------
if [ $ODOO_SERVER_NGINX_INSTALL == "true" ]
then
echo -e "\n---- Installing NGINX ----"
sudo apt-get install nginx -y

ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE="/etc/nginx/sites-available/$ODOO_SERVER_NGINX_CONFIG_FILE" #the config file
ODOO_SERVER_NGINX_CONFIG_FILE_ENABLED="/etc/nginx/sites-enabled/$ODOO_SERVER_NGINX_CONFIG_FILE" #the link path

echo -e "\n- NGINX config file location = $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE"

#Todo:maybe warn user that the default config will be changed
echo -e "\n---- Create NGINX config file"
sudo cp /etc/nginx/sites-enabled/default $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
sudo chown root:root $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
#sudo chmod 640 $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE

echo '################################################################################' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo 'NGINX configuration for $ODOO_SERVER_NGINX_URL' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '################################################################################' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo 'server {' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '	listen 80;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '	server_name $ODOO_SERVER_NGINX_URL;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '	add_header Strict-Transport-Security max-age=2592000;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '	rewrite ^/.*$ https://escape"$host$request_uri"? permanent;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '}' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE 
echo '' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE     
echo 'server {' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '  listen 443;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '  server_name $ODOO_SERVER_NGINX_URL;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '  proxy_set_header Host escape"$host";' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '  proxy_buffering off;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '	# add ssl specific settings' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '	# keepalive_timeout    240;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '	access_log  /var/log/nginx/oddo.access.log;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '	error_log   /var/log/nginx/oddo.error.log;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE    
echo '' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE   
echo '	ssl                          on;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '	ssl_certificate              /etc/nginx/ssl/server.crt;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE 
echo '	ssl_certificate_key          /etc/nginx/ssl/server.key;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '	ssl_session_timeout          10h;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE 
echo '	ssl_protocols                SSLv3 TLSv1;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '	ssl_ciphers                  HIGH:!ADH:!MD5;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE 
echo '	ssl_prefer_server_ciphers    on;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '	keepalive_timeout   240;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE 
echo '' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE

echo '	location / {' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '	proxy_pass http://$ODOO_SERVER_NGINX_URL:8069/;' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '	 }' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '}' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE
echo '' >> $ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE

#activate site
ln -s /$ODOO_SERVER_NGINX_CONFIG_FILE_AVAILABLE $ODOO_SERVER_NGINX_CONFIG_FILE_ENABLED
#restart service
service nginx reload
else
	echo -e "\n---- NGINX skipped ----"
fi

# Do some additional Odoo fixing
# Odoo 9.0 needs currently node-less installed
if [ $ODOO_GIT_VERSION == "9.0" ]	
then
	sudo apt-get install node-less
fi


echo "******************************************************************"
echo "	Installation of ODOO $ODOO_GIT_VERSION complete"
echo ""
echo "	Start/Stop server with /etc/init.d/$ODOO_CONFIGFILE_NAME"
echo ""
echo "	The server is available internaly:"
echo "	http://localhost:8069 "
if [ $ODOO_SERVER_NGINX_INSTALL == "true" ]
then
echo "	The server is available externaly:"
echo "	$ODOO_SERVER_NGINX_URL_PREFIX$ODOO_SERVER_NGINX_URL:$ODOO_SERVER_NGINX_PORT"
fi
echo "******************************************************************"

