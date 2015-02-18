# odoo-auto-install
Installing Odoo Server (formerly Open ERP) 

Simple guide:

	1.	Install fresh ubuntu 14.04 LTS
	2.	run => sudo apt-get install git
	3.	run => sudo git clone https://github.com/andreassantoro/odoo-auto-install.git
	4.	edit => sudo nano ./odoo-auto-install/odoo-auto-install 
	4.	run => sudo chmod 775 -R ./odoo-auto-install
	5.	run => sudo ./odoo-auto-install/odoo-auto-install

Settings:
	Important!

	LINE	:	SETTING

	#The version from GITHUB to install "8.0" / "7.0" / "master" / "saas-4"...
	17	:	ODOO_GIT_VERSION="8.0" 	#The admin password for odoo after installation
	
	#The admin password for odoo after installation
	21	:	ODOO_SERVER_ADMIN_PASSWORD="!superadmin123" 

	#The url your system will be available (only if nginx installation = truedo not add prefix http/https 
	30	:	ODOO_SERVER_NGINX_URL="odoo.mycompany.com" 