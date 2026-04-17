#!/usr/bin/env bash
# Copyright (c) Syncfusion Inc. All rights reserved.
#

# Stop script on NZEC
#set -e

# By default cmd1 | cmd2 returns exit code of cmd2 regardless of cmd1 success
# This is causing it to fail
#set -o pipefail

# Use in the the functions: eval $invocation
invocation='say_verbose "Calling: ${yellow:-}${FUNCNAME[0]} ${green:-}$*${white:-}"'

# standard output may be used as a return value in the functions
# we need a way to write text on the screen in the functions so that
# it won't interfere with the return value.
# Exposing stream 3 as a pipe to standard output of the script itself
exec 3>&1

verbose=true
args=("$@")
root_path="/application"
app_data_path="$root_path/app_data"
configuration_path="$app_data_path/configuration"
product_json_path="$configuration_path/product.json"
config_xml_path="$configuration_path/config.json"
id_path="$root_path/idp"
reporting_path="$root_path/reporting"
counter=0
is_success=false
etl_path="$root_path/etl/etlservice"
# Setup some colors to use. These need to work in fairly limited shells, like the Ubuntu Docker container where there are only 8 colors.
# See if stdout is a terminal
if [ -t 1 ] && command -v tput > /dev/null; then
    # see if it supports colors
    ncolors=$(tput colors)
    if [ -n "$ncolors" ] && [ $ncolors -ge 8 ]; then
        bold="$(tput bold       || echo)"
        normal="$(tput sgr0     || echo)"
        black="$(tput setaf 0   || echo)"
        red="$(tput setaf 1     || echo)"
        green="$(tput setaf 2   || echo)"
        yellow="$(tput setaf 3  || echo)"
        blue="$(tput setaf 4    || echo)"
        magenta="$(tput setaf 5 || echo)"
        cyan="$(tput setaf 6    || echo)"
        white="$(tput setaf 7   || echo)"
    fi
fi

say_warning() {
    printf "%b\n" "${yellow:-}configure_boldreports: Warning: $1${white:-}" >&3
}

say_err() {
    printf "%b\n" "${red:-}configure_bolreports: Error: $1${white:-}" >&2
}

say_success() {
    printf "%b\n" "${cyan:-}configure_boldreports: ${green:-}$1${white:-}" >&2
}

say_bold() {
    printf "%b\n" "${cyan:-}configure_boldreports: ${bold:-}$1${white:-}" >&2
}

say() {
    # using stream 3 (defined in the beginning) to not interfere with stdout of functions
    # which may be used as return value
        printf "%b\n" "${cyan:-}configure_boldreports: ${white:-}$1" >&3
}

say_verbose() {
    if [ "$verbose" = true ]; then
        say "$1"
    fi
}

# args:
# input - $1
to_lowercase() {
    #eval $invocation

    echo "$1" | tr '[:upper:]' '[:lower:]'
    return 0
}

# args:
# input - $1
remove_trailing_slash() {
    #eval $invocation

    local input="${1:-}"
    echo "${input%/}"
    return 0
}

# args:
# input - $1
remove_beginning_slash() {
    #eval $invocation

    local input="${1:-}"
    echo "${input#/}"
    return 0
}

start_boldreports_services() {
        eval $invocation

       syslogs="$app_data_path/logs/syslogs"
        if [ ! -d "$syslogs" ]; then
          mkdir -p "$syslogs"
        fi
		
        cd "$id_path/web/"
        nohup dotnet Syncfusion.Server.IdentityProvider.Core.dll --urls=http://localhost:6500 &> "$syslogs/id_web.txt" &
        say "Starting IDP Web application [Identity Provider Web for Bold Enterprise Products.]"

        check_config_file_generated

        dotnet "$root_path/clientlibrary/MoveSharedFiles/MoveSharedFiles.dll"
        sleep 10s

        install_client_libraries
        sleep 20s

        cd "$id_path/api/"
        nohup dotnet Syncfusion.Server.IdentityProvider.API.Core.dll --urls=http://localhost:6501 &> "$syslogs/id_api.txt" &
		say "Starting IDP API application [Identity Provider REST API for Bold Enterprise Products.]"

        cd "$id_path/ums/"
        nohup dotnet Syncfusion.TenantManagement.Core.dll --urls=http://localhost:6502 &> "$syslogs/id_ums.txt" &
        say "Starting UMS application [Tenant and User Management for Bold Enterprise Products.]"

        cd "$reporting_path/web/"
        nohup dotnet Syncfusion.Server.Reports.dll --urls=http://localhost:6504 &> "$syslogs/reports_web.txt" &
        say "Starting Reports Web application [Dashboard Server for Bold Reports.]"

        cd "$reporting_path/api/"
        nohup dotnet Syncfusion.Server.API.dll --urls=http://localhost:6505 &> "$syslogs/reports_api.txt" &
        say "Starting Reports API application [Reports API Service for Bold Reports.]"

        cd "$reporting_path/jobs/"
        nohup dotnet Syncfusion.Server.Jobs.dll --urls=http://localhost:6506 &> "$syslogs/reports_jobs.txt" &
        say "Starting Reports Jobs application [Reports Jobs Service for Bold Reports.]"

        cd "$reporting_path/viewer/"
        nohup dotnet Syncfusion.Server.Viewer.dll --urls=http://localhost:6507 &> "$syslogs/reports_viewer.txt" &
        say "Starting Reports Viewer application [Reports Viewer Service for Bold Reports.]"

        cd "$reporting_path/reportservice/"
        nohup dotnet BoldReports.Server.Services.dll --urls=http://localhost:6508 &> "$syslogs/reports_designer.txt" &
        say "Starting Reports Designer application [Reports Designer Service for Bold Reports.]"

        # if ping -q -c 1 -W 1 "8.8.8.8" >/dev/null; then
        # cd "$root_path"
        # install_chrome_package
        # else
        # cd "$root_path"
        # move_chrome_package
        # fi

        cd "$etl_path"
        nohup dotnet BoldDataHub.dll --urls=http://localhost:6509 &> "$syslogs/etl.txt" &
        say "Starting ETL application [ETL Service for Bold Reports.]"
}

check_config_file_generated() {
        eval $invocation

        ## code to check whether the config.xml file is generated or not
        say "Initializing configuration files..."

        while :
        do
                if [ -f "$config_xml_path" ]; then
                        break
                fi
        done

        say_success "Config files generated successfully."
        ##
}
upgrade_log() {
    if [ -f $product_json_path ]; then
	
	exclude_folders=("logs" "upgradelogs")
	
	[ ! -d "$app_data_path/upgradelogs" ] && mkdir -p "$app_data_path/upgradelogs"
	
	json_file="$product_json_path"

	# Read the JSON file into a variable
	json_data=$(cat "$json_file")

	# Search for the version key and extract the version value
	version=$(echo "$json_data" | grep -o '"Version": "[^"]*' | sed 's/"Version": "//')
	
	if [ -d "$app_data_path/upgradelogs/$version" ]; then
    rm -r "$app_data_path/upgradelogs/$version"
    fi
	mkdir -p "$app_data_path/upgradelogs/$version"
	
	find "$app_data_path" -type d \( -name "${exclude_folders[0]}" -o -name "${exclude_folders[1]}" \) -prune -o -print > "$app_data_path/upgradelogs/$version/upgrade_logs.txt"
    fi
}
update_url_in_product_json() {
        eval $invocation

        say "Checking whether product.json exists in app_data folder."
        if [ ! -f $product_json_path ]; then

                if [ -z $APP_URL ]; then
                        mkdir -p $configuration_path && cp -rf product.json $product_json_path
                else
                        export IDPURL=$APP_URL
                        jq --arg IDPURL "$IDPURL" '.InternalAppUrl.Idp=$IDPURL' product.json > out1.json

                        export REPORTURL=$APP_URL"/reporting"
                        jq --arg REPORTURL "$REPORTURL" '.InternalAppUrl.Reports=$REPORTURL' out1.json > out2.json

                        export REPORTDESIGNERURL=$APP_URL"/reporting/reportservice"
                        jq --arg REPORTDESIGNERURL "$REPORTDESIGNERURL" '.InternalAppUrl.ReportsService=$REPORTDESIGNERURL' out2.json > out3.json

                        mkdir -p /application/app_data/configuration/ && cp -rf out3.json /application/app_data/configuration/product.json
                        rm out1.json out2.json out3.json
                fi
                say_success "Updated product.json with APP_URL and moved to app_data folder."
        else
                dotnet "$root_path/clientlibrary/MoveSharedFiles/MoveSharedFiles.dll" upgrade_version docker
        fi
}
update_nginx_configuration() {

nginx_conf="/etc/nginx/sites-available/boldreports-nginx-config"

viewer_location_block=$(cat <<EOL
        location /reporting/viewer {
        root               /application/reporting/viewer;
        proxy_pass         http://localhost:6507/;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection "keep-alive";
        proxy_set_header   Host \$http_host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
    }
}
EOL
)

etl_location_block=$(cat <<EOL
        location /etlservice/ {
        root               /application/etl/etlservice/wwwroot;
        proxy_pass         http://localhost:6509/;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host \$http_host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
    }
        location /etlservice/_framework/blazor.server.js {
        root               /application/etl/etlservice/wwwroot;
        proxy_pass         http://localhost:6509/_framework/blazor.server.js;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection "upgrade";
        proxy_set_header   Host \$http_host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
   }
}
EOL
)

if ! grep -Eq "location .*/viewer.*" "$nginx_conf"; then
    # Append the new location block to the end of the file
    sed -i '${/}/d;}' $nginx_conf
    echo "$viewer_location_block" >> "$nginx_conf"
    echo "Viewer location block added in Nginx file"
fi

if ! grep -Eq "location .*/etlservice/.*" "$nginx_conf"; then
    # Append the new location block to the end of the file
    sed -i '${/}/d;}' $nginx_conf
    echo "$etl_location_block" >> "$nginx_conf"
    echo "ETL location block added in Nginx file"
fi
}

configure_nginx () {
        eval $invocation

        say "Configuring Nginx web server."
        cd $root_path
		
		if [ "$BOLD_SERVICES_REVERSE_PROXY" = "True" ] || [ "$BOLD_SERVICES_REVERSE_PROXY" = "true" ]; then
			sed -i 's/proxy_set_header   X-Forwarded-Proto $scheme;/proxy_set_header   X-Forwarded-Proto $http_x_forwarded_proto;/' boldreports-nginx-config
		fi		

        if [ "$OS_ENV" != "alpine" ]; then
                nginx_sites_available_dir="/etc/nginx/sites-available"
                nginx_sites_enabled_dir="/etc/nginx/sites-enabled"

                if [ ! -f $nginx_sites_available_dir/boldreports-nginx-config ]; then
                        [ ! -d "$nginx_sites_available_dir" ] && mkdir -p "$nginx_sites_available_dir"
                        [ ! -d "$nginx_sites_enabled_dir" ] && mkdir -p "$nginx_sites_enabled_dir"

                        cp boldreports-nginx-config $nginx_sites_available_dir/boldreports-nginx-config
                fi
				update_nginx_configuration
                [ ! -f "$nginx_sites_enabled_dir/boldreports-nginx-config" ] && ln -sf $nginx_sites_available_dir/boldreports-nginx-config $nginx_sites_enabled_dir/default
        else
                echo "include /etc/nginx/sites-available/boldreports-nginx-config;" > /etc/nginx/http.d/default.conf 

                nginx_sites_available_dir="/etc/nginx/sites-available"

                if [ ! -f $nginx_sites_available_dir/boldreports-nginx-config ]; then
                        [ ! -d "$nginx_sites_available_dir" ] && mkdir -p "$nginx_sites_available_dir"
                        cp boldreports-nginx-config $nginx_sites_available_dir/boldreports-nginx-config
                fi
        fi

        nginx -c /etc/nginx/nginx.conf
        say "Starting Nginx web server."
}


install_client_libraries() {
        eval $invocation
	# Eliminate special characters and spaces.
        OPTIONAL_LIBS=$(echo "$OPTIONAL_LIBS" | tr -dc '[:alpha:],')
        # Eliminate any extra commas if there are any available.
        OPTIONAL_LIBS=$(echo "$OPTIONAL_LIBS" | sed 's/,\+/,/g')
    bash $root_path/clientlibrary/install-optional.libs.sh install-optional-libs $OPTIONAL_LIBS
}

# install_chrome_package() {

#         puppeteer_location="$app_data_path/reporting/exporthelpers/puppeteer"
#         cd $root_path
#         if [ ! -d "$puppeteer_location/chrome-linux" ]; then
#             eval $invocation
                            
#             [ ! -d "$app_data_path/reporting" ] && mkdir -p "$app_data_path/reporting"
#             [ ! -d "$app_data_path/reporting/exporthelpers" ] && mkdir -p "$app_data_path/reporting/exporthelpers"
#             [ ! -d "$puppeteer_location" ] && mkdir -p "$puppeteer_location"
#             dotnet "utilities/adminutils/Syncfusion.Server.Commands.Utility.dll" "installpuppeteer" -path "$puppeteer_location"
#         fi

#         if [ -d "$puppeteer_location/Linux-901912" ]; then
#             say "Chrome package installed successfully"
#             [ -f "$app_data_path/reporting/exporthelpers/phantomjs" ] && rm -rf "$app_data_path/reporting/exporthelpers/phantomjs"
#         fi

# }

move_chrome_package(){

        puppeteer_location="$app_data_path/reporting/exporthelpers/puppeteer"
        cd $root_path
        if [ ! -d "$puppeteer_location/Linux-901912" ]; then
                eval $invocation

                [ ! -d "$app_data_path/reporting" ] && mkdir -p "$app_data_path/reporting"
                [ ! -d "$app_data_path/reporting/exporthelpers" ] && mkdir -p "$app_data_path/reporting/exporthelpers"
                [ ! -d "$puppeteer_location" ] && mkdir -p "$puppeteer_location"
				[ ! -d "$puppeteer_location/Linux-901912" ] && mkdir -p "$puppeteer_location/Linux-901912"
                unzip "chrome-linux.zip" -d "$puppeteer_location/Linux-901912" > $syslogs/chrome.txt 2>&1
		        chmod +x "$puppeteer_location"/Linux-901912/chrome-linux/*
        fi

        if [ -d "$puppeteer_location/Linux-901912" ]; then
            say "Chrome package installed successfully"
            [ -f "$app_data_path/reporting/exporthelpers/phantomjs" ] && rm -rf "$app_data_path/reporting/exporthelpers/phantomjs"
        fi
}

final_configuration() {
        eval $invocation

        ## code to check whether all services were running or not
        APP_URL=($(cat $product_json_path | jq '.InternalAppUrl.Idp'))
        APP_URL=$(eval echo $APP_URL)
        domain="$(remove_trailing_slash "$APP_URL")"
       # domain=$(basename "$APP_URL")
        health_check_endpoint="$domain/api/status"
        keyword1='"is_running":true'
        keyword2='"is_running":false'

        say "Completing final configuration. Please wait..."

        while sleep 5; do
                counter=$((counter+1))

                if curl -s "$health_check_endpoint" | grep -q "$keyword1"
                then
                        say "This may take some time..."
                        while :
                        do
                                if ! curl -s "$health_check_endpoint" | grep -q "$keyword2"
                                then
                                        is_success=true
                                        break
                                fi
                        done
                        break
                elif [[ "$counter" -eq 18 ]]; then
                    say "This is taking more time than usual. Please wait..."
                elif [[ "$counter" -gt 36 ]]; then
                        say "Please check whether your domain in APP_URL is correct. Unable to configure boldreports with $domain"
                        break
                fi
        done

    if $is_success; then
            say_success "Bold Reports configuration completed successfully."
            say_success "Bold Reports is ready to use now.You can access Bold Reports application in your browser at http://localhost:port-number or http://host-ip:port-number."
        fi
}

final_notes() {
        if [ ! -n "$BOLD_SERVICES_UNLOCK_KEY" ]; then
          eval $invocation
          say "Configure the Bold Reports On-Premise application startup to use the application."
	  say "Please refer the following link for more details"
	  say "https://help.boldreports.com/enterprise-reporting/administrator-guide/application-startup"
	  say "Please refer here for Bold Reports Enterprise documentation => https://help.boldreports.com/enterprise-reporting/"
        fi

}

scan_services() {

    service_message_shown_id_web=false
    service_message_shown_id_api=false
    service_message_shown_id_ums=false
    service_message_shown_reports_web=false
    service_message_shown_reports_api=false
    service_message_shown_reports_jobs=false
    service_message_shown_reports_dataservice=false
    service_message_shown_etl=false
    while sleep 60; do
        ps aux | grep Syncfusion.Server.IdentityProvider.Core.dll | grep -q -v grep
        PROCESS_1_STATUS=$?

        ps aux | grep Syncfusion.Server.IdentityProvider.API.Core.dll | grep -q -v grep
        PROCESS_2_STATUS=$?

        ps aux | grep Syncfusion.TenantManagement.Core.dll | grep -q -v grep
        PROCESS_3_STATUS=$?

        ps aux | grep Syncfusion.Server.Reports.dll | grep -q -v grep
        PROCESS_4_STATUS=$?

        ps aux |grep Syncfusion.Server.API.dll |grep -q -v grep
        PROCESS_5_STATUS=$?

        ps aux |grep Syncfusion.Server.Jobs.dll |grep -q -v grep
        PROCESS_6_STATUS=$?

        ps aux |grep Syncfusion.Server.Viewer.dll |grep -q -v grep
        PROCESS_7_STATUS=$?

        ps aux |grep BoldReports.Server.Services.dll |grep -q -v grep
        PROCESS_8_STATUS=$?
        
        ps aux | grep BoldDataHub.dll | grep -q -v grep
        PROCESS_9_STATUS=$?

        if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 -o $PROCESS_3_STATUS -ne 0 -o $PROCESS_4_STATUS -ne 0 -o $PROCESS_5_STATUS -ne 0 -o $PROCESS_6_STATUS -ne 0 -o $PROCESS_7_STATUS -ne 0 -o $PROCESS_8_STATUS -ne 0 -o $PROCESS_9_STATUS -ne 0 ]; then

            # Restart the services one by one if they are down
            if [ $PROCESS_1_STATUS -ne 0 ]; then
                if ! $service_message_shown_id_web; then
                    say "The IDP Web service is down. You can find the reason for the service being down from the service logs available at the \"$syslogs\" location."
                    service_message_shown_id_web=true
                fi

            fi

            if [ $PROCESS_2_STATUS -ne 0 ]; then
                if ! $service_message_shown_id_api; then
                    say "The IDP API service is down. You can find the reason for the service being down from the service logs available at the \"$syslogs\" location."
                    service_message_shown_id_api=true
                fi

            fi

            if [ $PROCESS_3_STATUS -ne 0 ]; then
                if ! $service_message_shown_id_ums; then
                    say "The IDP UMS service is down. You can find the reason for the service being down from the service logs available at the \"$syslogs\" location."
                    service_message_shown_id_ums=true
                fi

            fi

            if [ $PROCESS_4_STATUS -ne 0 ]; then
                if ! $service_message_shown_reports_web; then
                    say "The Reports Web service is down. You can find the reason for the service being down from the service logs available at the \"$syslogs\" location."
                    service_message_shown_reports_web=true
                fi
            fi

            if [ $PROCESS_5_STATUS -ne 0 ]; then
                if ! $service_message_shown_reports_api; then
                    say "The Reports API service is down. You can find the reason for the service being down from the service logs available at the \"$syslogs\" location."
                    service_message_shown_reports_api=true
                fi

            fi

            if [ $PROCESS_6_STATUS -ne 0 ]; then
                if ! $service_message_shown_reports_jobs; then
                    say "The Reports Jobs service is down. You can find the reason for the service being down from the service logs available at the \"$syslogs\" location."
                    service_message_shown_reports_jobs=true
                fi
            fi

            if [ $PROCESS_7_STATUS -ne 0 ]; then
                if ! $service_message_shown_reports_viewer; then
                    say "The Reports Viewer service is down. You can find the reason for the service being down from the service logs available at the \"$syslogs\" location."
                    service_message_shown_reports_viewer=true
                fi
           fi

            if [ $PROCESS_8_STATUS -ne 0 ]; then
                if ! $service_message_shown_reports_dataservice; then
                    say "The Reports Designer service is down. You can find the reason for the service being down from the service logs available at the \"$syslogs\" location."
                    service_message_shown_reports_dataservice=true
                fi
           fi

            if [ $PROCESS_9_STATUS -ne 0 ]; then
                if ! $service_message_shown_etl; then
                    say "The ETL service is down. You can find the reason for the service being down from the service logs available at the \"$syslogs\" location."
                  service_message_shown_etl=true
                fi
            fi
        else
            # Reset the error_shown and service_message_shown flags

                        service_message_shown_id_web=false
                        service_message_shown_id_api=false
                        service_message_shown_id_ums=false
                        service_message_shown_reports_web=false
                        service_message_shown_reports_api=false
                        service_message_shown_reports_jobs=false
                        service_message_shown_reports_viewer=false
                        service_message_shown_reports_dataservice=false
                        service_message_shown_etl=false
        fi
    done
}


configure_boldreports() {
        eval $invocation
        
	upgrade_log
        update_url_in_product_json
        start_boldreports_services
        move_chrome_package
        configure_nginx
        final_configuration
        if $is_success; then final_notes; fi
        scan_services
}

configure_boldreports
