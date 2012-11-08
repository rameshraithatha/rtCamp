##!/bin/bash

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


#-----Begin------------------------------------------------------------------------------------

if [[ `id -u` -ne 0 ]]  # Check if the user is root or not
then
	echo $bold"You need to be root to access this script!"$normal
else
	bold=`tput bold`   # Changes text into bold
	normal=`tput sgr0` # Changes text into normal mode

packagecheck(){
	echo $bold"Installing missing packages, please wait!"$normal
	#apt-get update
	for i in  nginx mysql-server php5 php5-fpm php5-mysql
	do
	dpkg --status $i > /dev/null
	if [[ $? -ne 0 ]]
	then
		apt-get -f install $i
		if [[ $? -eq 0 ]]
		then
			echo $bold"$i installed successfully"$normal
		else
			echo $bold"Some error occured!"$normal
			exit 1
		fi
	fi
	done

	if [[ $? -ne 0 ]]
	then
		echo $bold"Some error occured!"$normal
		exit 1
	fi
	}

domain(){
	read -p $bold"Enter your domain name: $normal" domain;echo ""
}

hostentry(){
	echo "127.0.0.1	$domain" >> /etc/hosts
}

	
createconfig() {
	echo $bold"Creating config file for nginx"$normal

	echo "server
	{
	    server_name $domain;

	    access_log /usr/share/nginx/$domain/access.log;

	    error_log /usr/share/nginx/$domain/error.log;

	    root /usr/share/nginx/$domain/www;

	    index index.php index.html index.htm;
	
	    location ~ \.php$ {
	    include /etc/nginx/fastcgi_params;
	    fastcgi_pass 127.0.0.1:9000;
	    fastcgi_index index.php;
	    fastcgi_param SCRIPT_FILENAME /usr/share/$domain/www\$fastcgi_script_name;
}

	}" > /etc/nginx/sites-available/$domain
	ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/$domain
	if [[ $? -eq 0 ]]
	then
		echo $bold"nginx config file created"$normal
	else
		echo $bold"Some error occured wile creating/linking nginx config file"$normal
	fi
	/etc/init.d/nginx reload
	}
	
downloadwp(){
	mkdir -p /usr/share/nginx/$domain/www
	wget http://wordpress.org/latest.zip -P /usr/share/nginx/$domain/www
	unzip /usr/share/nginx/$domain/www/latest.zip
}

mysqldb(){	
	echo $bold"Creating mysql database"$normal
	read -p $bold"Enter mysql user name: "$normal mysqluser;echo
	read -p $bold"Enter mysql password: "$normal -s mysqlpass;echo

	mysql -u $mysqluser -p$mysqlpass -e "create database ${domain}_db;" 2> db.log
	
	if cat db.log | grep -wE "database exists" > dberr.log
	then
		echo $bold"Database already exists, check dberr.log for more information"$normal
	elif at db.log | grep -wE "ERROR 1045" > dberr.log
	then
		echo $bold"Access denied, check username/password, check dberr.log for more information"$normal
		exit 1
	else
		echo $bold"Unknow error occured, check dberr.log for more information"$normal
		exit 1
	fi
	
}


wpconfig(){
	echo $bold"Creating wordpress config file"$normal
	cd /usr/share/nginx/$domain/www/wordpress

	cp wp-config-sample.php wp-config.php

	sed -i "s/database_name_here/"$domain"_db/g" wp-config.php
	sed -i "s/username_here/"$mysqluser"/g" wp-config.php
	sed -i "s/password_here/"$mysqlpass"/g" wp-config.php
	if [[ $? -eq 0 ]]
	then
		echo $bold"wordpress config file created"$normal
	else
		echo $bold"Some error occured wile creating wordpress config file"$normal
	fi
}

packagecheck
domain
hostentry
createconfig
downloadwp
#mysqldb
wpconfig
if [[ $? -eq 0 ]]
then
	echo $bold"Open $domain in a browser"$normal
fi

fi
