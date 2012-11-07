#!/bin/bash

#Written by - Ramesh Raithatha
#Email - ramesh_raithatha@hotmail.com
	
#1.Your script will check if PHP, Mysql & Nginx are installed. If not present, missing packages will be installed.
#2. The script will then ask user for domain name. (Suppose user enters example.com)
#3.Create a /etc/hosts entry for example.com pointing to localhost IP.
#4.Create nginx config file for example.com
#5.Download WordPress latest version from http://wordpress.org/latest.zip and unzip it locally in example.com document root.
#6.Create a new mysql database for new wordpress. (database name “example.com_db” )
#7.Create wp-config.php with proper DB configuration. (You can use wp-config-sample.php as your template)
#8.You may need to fix file permissions, cleanup temporary files, restart or reload nginx config.
#9.Tell user to open example.com in browser (if all goes well)



#-----Begin-----
#Your script will check if PHP, Mysql & Nginx are installed. If not present, missing packages will be installed.

if [[ `id -u` -ne 0 ]]  # Check if the user is root or not
then
	echo "You need to be root to access this script!"
else
	for i in "mysql-server php5 nginx"
	do
		dpkg --status $i > err.log # 1> success.log
		#echo `dpkg --status $i | grep -q not-installed` > rtcamp1.log
		cat err.log | grep -w "not-	installed" > 1
		if [[ $? -eq 0 ]]
		then
	    		apt-get install $i
		fi
		#echo "" > err.log
		#echo "" > 1

	done


	#-->The script will then ask user for domain name. (Suppose user enters example.com)

	read -p "Enter your domain name: " domain;echo ""


	#-->Create a /etc/hosts entry for example.com pointing to localhost IP.

	echo "127.0.0.1	$domain" >> hosts


	#-->Create nginx config file for example.com

	mkdir /var/www/$domain

	echo "server
	{
	    server_name $domain;

	    access_log /var/log/nginx/$domain.access.log;

	    error_log /var/log/nginx/$domain.error.log;

	    root /var/www/$domain;

	    index index.php index.html index.htm;

	    location ~ \.php$
	    {
		fastcgi_pass 127.0.0.1:9000;
		fastcgi_index index.php;
		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
		include fastcgi_params;
	    }

	}" > /etc/nginx/sites-available/$domain

	/etc/init.d/nginx reload


	#Download WordPress latest version from http://wordpress.org/latest.zip and unzip it locally in example.com document root.

	wget http://wordpress.org/latest.zip -P /var/www/$domain

	unzip /var/www/$domain/latest.zip


	#Create a new mysql database for new wordpress. (database name “example.com_db” )
	read -p "Enter mysql user name: " mysqluser;echo ""
	read -p "Enter mysql password: " -s mysqlpass;echo ""

	mysql -u $mysqluser -p$mysqlpass -e "create database $domain_db;"



	#Create wp-config.php with proper DB configuration. (You can use wp-config-sample.php as your template)


	cd /var/www/$domain/latest.zip

	cp wp-config-sample.php wp-config.php

	sed -i "s/database_name_here/"$domain"_db/g" wp-config.php
	sed -i "s/username_here/"$mysqluser"/g" wp-config.php
	sed -i "s/password_here/"$mysqlpass"/g" wp-config.php


fi


echo "Open $domain in a browser"



