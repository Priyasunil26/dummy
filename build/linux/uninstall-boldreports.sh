#!/usr/bin/env bash
# Copyright (c) Syncfusion Inc. All rights reserved.

services_array=("bold-id-web" "bold-id-api" "bold-ums-web" "bold-reports-web" "bold-reports-api" "bold-reports-jobs" "bold-reports-service" "bold-etl" "bold-reports-viewer")

uninstall_boldreports() {
                if [ ! -d "/var/www/bold-services/application/etl" ]; then
                        services_array=("bold-id-web" "bold-id-api" "bold-ums-web" "bold-reports-web" "bold-reports-api" "bold-reports-jobs" "bold-reports-service" "bold-reports-viewer")
                fi        
                stop_boldreports_services
                echo "Removing Bold Reports Service Files"
                for file in "${services_array[@]}"; do
                    rm -f /etc/systemd/system/"${file}.service"
                done
                echo "Removing Bold Reports Installed Files"
                rm -rf /var/www/bold-*
		centos_apche="/etc/httpd/sites-enabled/boldreports-apache-config.conf"
		centos_nginx="/etc/nginx/conf.d/boldreports-nginx-config.conf"
		nginx_config="/etc/nginx/sites-enabled/boldreports-nginx-config"
                apache_config="/etc/apache2/sites-enabled/boldreports-apache-config.conf"

                # Check if boldreports-nginx-config exists and remove it if it does
                if [ -f "$nginx_config" ]; then
                echo "Removing boldreports-nginx-config..."
                rm "$nginx_config"
                echo "boldreports-nginx-config removed."
                fi
		# Check if boldreports-nginx-config exists and remove it if it does
                if [ -f "$centos_nginx" ]; then
                echo "Removing boldreports-nginx-config..."
                rm "$centos_nginx"
                echo "boldreports-nginx-config removed."
                fi
                # Check if boldreports-apache-config exists and remove it if it does
                if [ -f "$centos_apche" ]; then
                echo "Removing boldreports-apache-config..."
                rm "$centos_apche"
                echo "boldreports-apache-config removed."
                fi
		# Check if boldreports-apache-config exists and remove it if it does
                if [ -f "$apache_config" ]; then
                echo "Removing boldreports-apache-config..."
                rm "$apache_config"
                echo "boldreports-apache-config removed."
                fi
                echo "Bold Reports Uninstalled Successfully.."
                   }
stop_boldreports_services() {
				for t in ${services_array[@]}; do
    				echo "Disabling service - $t"
				systemctl disable $t
				echo "Stopping service - $t"
				systemctl stop $t
				done
						}
read -p "Do you wish to Uninstall Bold Reports? [yes / no]:" yn
			case $yn in
				[Yy]* ) uninstall_boldreports;;
				[Nn]* ) exit;;
				* ) echo "Please answer yes or no.";;
			esac