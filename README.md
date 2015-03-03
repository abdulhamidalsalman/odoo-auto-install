# odoo-auto-install
Installing Odoo Server (formerly Open ERP) 

Simple guide:

	1.	Install fresh ubuntu 14.04 LTS
	2.	sudo apt-get install git 	#Install git
	3.	sudo git clone https://github.com/andreassantoro/odoo-auto-install.git  #clone the auto install repository
	4.	sudo nano odoo-auto-install/odoo-auto-install #configure your odoo installation
	5.	sudo chmod 775 -R odoo-auto-install #make the script executable
	6.	sudo odoo-auto-install/install_odoo.sh #start the installation
	7.	restart the server :-)

Settings:
	Important!

	#The version from GITHUB to install "8.0" / "7.0" / "master" / "saas-4"...
	17	:	ODOO_GIT_VERSION="8.0" 
	
	#The admin password for odoo after installation
	21	:	ODOO_SERVER_ADMIN_PASSWORD="!superadmin123" 

	#The url your system will be available (only if nginx installation = truedo not add prefix http/https 
	30	:	ODOO_SERVER_NGINX_URL="odoo.mycompany.com" 