#!/usr/bin/env bash
# Copyright (c) Syncfusion Inc. All rights reserved.
#

# Stop script on NZEC
set -e
# Stop script if unbound variable found (use ${var:-} if intentional)
set -u
# By default cmd1 | cmd2 returns exit code of cmd2 regardless of cmd1 success
# This is causing it to fail
set -o pipefail

# Use in the the functions: eval $invocation
invocation='say_verbose "Calling: ${yellow:-}${FUNCNAME[0]} ${green:-}$*${normal:-}"'

# standard output may be used as a return value in the functions
# we need a way to write text on the screen in the functions so that
# it won't interfere with the return value.
# Exposing stream 3 as a pipe to standard output of the script itself
exec 3>&1

verbose=true
args=("$@")
install_dir="/var/www/bold-services"
backup_folder="/var/www"
dotnet_dir="$install_dir/dotnet"
services_dir="$install_dir/services"
system_dir="/etc/systemd/system"
boldreports_product_json_location="$install_dir/application/app_data/configuration/product.json"
nginx_config_file_location="/etc/nginx/sites-available/boldreports-nginx-config"
user=""
host_url=""
ssl_cert_path=""
ssl_key_path=""
distribution=""
lic_key=""
db_type=""
db_host=""
db_user=""
db_pwd=""
db_name=""
db_port=""
maintain_db=""
email=""
epwd=""
add_parameters=""
main_logo=""
login_logo=""
email_logo=""
favicon=""
footer_logo=""
show_copyright_info="true"
optional_libs=""
site_name=""
site_identifier=""
use_siteidentifier=""
can_configure_nginx=false
declare -A separated_services=( ["viewer"]="reporting\/viewer" ["etl"]="etlservice" )
services_array=("bold-id-web" "bold-id-api" "bold-ums-web" "bold-reports-web" "bold-reports-api" "bold-reports-jobs" "bold-reports-service" "bold-reports-viewer" "bold-etl")
installation_type=""
app_data_location="$install_dir/application/app_data"
puppeteer_location="$app_data_location/reporting/exporthelpers/puppeteer"
configuration_dir="$app_data_location/configuration"

while [ $# -ne 0 ]
do
    name="$1"
    case "$name" in
        -d|--install-dir|-[Ii]nstall[Dd]ir)
            shift
            install_dir="$1"
            ;;
			
		-i|--install|-[Ii]nstall)
            shift
            installation_type="$1"
            ;;
			
		-u|--user|-User)
            shift
            user="$1"
            ;;
			
		-h|--host|-[Hh]ost)
            shift
            host_url="$1"
            ;;
        
		-n|--nginx|-[Nn]ginx)
            shift
            can_configure_nginx="$1"
            ;;
		
		--ssl-cert|-[Ss][Ss][Ll][Cc]ert)
            shift
            ssl_cert_path="$1"
            ;;
        --ssl-key|-[Ss][Ss][Ll][Kk]ey)
            shift
            ssl_key_path="$1"
            ;;
		
		-[Ll]icense)
		  shift
		  lic_key="$1"
		  ;;

		-[Dd]atabasetype)
		  shift
		  db_type="$1"
		  ;;

		-[Dd]atabasehost)
		  shift
		  db_host="$1"
		  ;;

		-[Dd]atabaseport)
		  shift
		  db_port="$1"
		  ;;		  

		-[Dd]atabasename)
		  shift
		  db_name="$1"
		  ;;

		-[Mm]aintaindb)
		  shift
		  maintain_db="$1"
		  ;;

		-[Dd]atabaseuser)
		  shift
		  db_user="$1"
		  ;;

		-[Dd]atabasepwd)
		  shift
		  db_pwd="$1"
		  ;;

		-[Aa]dditionalparameters)
		  shift
		  add_parameters="$1"
		  ;;

		-[Uu]sesiteidentifier)
		  shift
		  use_siteidentifier="$1"
		  ;;

		-[Ee]mail)
		  shift
		  email="$1"
		  ;;

		-[Ee]mailpwd)
		  shift
		  epwd="$1"
		  ;;
		  
		-[Mm]ainlogo)
		  shift
		  main_logo="$1"
		  ;;
		  
		-[Ll]oginlogo)
		  shift
		  login_logo="$1"
		  ;;
		  
		-[Ee]maillogo)
		  shift
		  email_logo="$1"
		  ;;
		  
		-[Ff]avicon)
		  shift
		  favicon="$1"
		  ;;
		  
		-[Ff]ooterlogo)
		  shift
		  footer_logo="$1"
		  ;;
		
		-[Ss]itename)
		  shift
		  site_name="$1"
		  ;;
		  
		-[Ss]iteidentifier)
		  shift
		  site_identifier="$1"
		  ;;
		
		-[Cc]opyrightinfo) 
		  shift 
		  show_copyright_info="$1" 
		  ;;
		
		-[Oo]ptionallibs)
      	  shift
	  	  optional_libs="$1"
      	  ;;

        -?|--?|--help|-[Hh]elp)
            script_name="$(basename "$0")"
            echo "Bold Reports Installer"
            echo "Usage: $script_name [-u|--user <USER>]"
            echo "       $script_name |-?|--help"
            echo ""
            exit 0
            ;;
        *)
            say_err "Unknown argument \`$name\`"
            exit 1
            ;;
    esac

    shift
done

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
    printf "%b\n" "${yellow:-}boldreports_install: Warning: $1${normal:-}" >&3
}

say_err() {
    printf "%b\n" "${red:-}boldreports_install: Error: $1${normal:-}" >&2
}

say() {
    # using stream 3 (defined in the beginning) to not interfere with stdout of functions
    # which may be used as return value
    printf "%b\n" "${cyan:-}boldreports-install:${normal:-} $1" >&3
}

say_verbose() {
    if [ "$verbose" = true ]; then
        say "$1"
    fi
}

machine_has() {
    eval $invocation

    hash "$1" > /dev/null 2>&1
    return $?
}

check_min_reqs() {
    # local hasMinimum=false
    # if machine_has "curl"; then
        # hasMinimum=true
    # elif machine_has "wget"; then
        # hasMinimum=true
    # fi

    # if [ "$hasMinimum" = "false" ]; then
        # say_err "curl or wget are required to download Bold BI. Install missing prerequisite to proceed."
        # return 1
    # fi
	
	local hasZip=false
	if machine_has "zip"; then
        hasZip=true
    fi
	
	if [ "$hasZip" = "false" ]; then
        say_err "Zip is required to extract the Bold Reports Linux package. Install missing prerequisite to proceed."
        return 1
    fi
	
	if ! machine_has "python3"; then
	    say_err "python3 is required for installing Bold Reports. Install the missing prerequisite to proceed."
	    return 1
	fi
 
	if ! machine_has "pip" && ! machine_has "pip3"; then
	    say_err "python3-pip is required for installing Bold Reports. Install the missing prerequisite to proceed."
	    return 1
	fi
	
	local hasNginx=false
	if machine_has "nginx"; then
        hasNginx=true
    fi
	
	if [ "$hasNginx" = "false" ]; then
        say_err "Nginx is required to host the Bold Reports application. Install missing prerequisite to proceed."
        return 1
    fi
	
    return 0
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


enable_boldreports_services() {
	eval $invocation
	for t in ${services_array[@]}; do
		if is_service_already_exists "$t"; then
			say "Enabling service - $t"
			systemctl enable $t
		else
			say_err "Unable to enable service - $t"
		fi
	done
}

copy_files_to_installation_folder() {
	eval $invocation
	
	cp -a application/. $install_dir/application/
	cp -a uninstall-boldreports.sh $install_dir/uninstall-boldreports.sh
	cp -a clientlibrary/. $install_dir/clientlibrary/
	cp -a dotnet/. $install_dir/dotnet/
	cp -a services/. $install_dir/services/
	cp -a Infrastructure/. $install_dir/Infrastructure/
}

start_boldreports_services() {
	eval $invocation
	for t in ${services_array[@]}; do
		if is_service_already_exists "$t"; then
			say "Starting service - $t"
			systemctl start $t
			
			if [ $t = "bold-id-web" ]; then
			    say "Initializing $t"
			    sleep 5
			fi
		else
			say_err "Unable to start service - $t"
		fi
	done
}

status_boldreports_services() {
	eval $invocation
	systemctl --type=service | grep bold-*
}

stop_boldreports_services() {
	eval $invocation
	for t in ${services_array[@]}; do
		if is_service_already_exists "$t"; then
			say "Stopping service - $t"
			systemctl stop $t
		fi
	done
}

restart_boldreports_services() {
	eval $invocation
	for t in ${services_array[@]}; do
		if is_service_already_exists "$t"; then
			say "Restarting service - $t"
			systemctl restart $t
			
			if [ $t = "bold-id-web" ]; then
			    say "Initializing $t"
			    sleep 5
			fi
		else
			say_err "Unable to restart service - $t"
		fi
	done
}

chrome_package_installation() {
	eval $invocation

	if [ ! -d "$puppeteer_location/Linux-901912" ]; then
		[ ! -d "$app_data_location/reporting" ] && mkdir -p "$app_data_location/reporting"
		[ ! -d "$app_data_location/reporting/exporthelpers" ] && mkdir -p "$app_data_location/reporting/exporthelpers"
		[ ! -d "$puppeteer_location" ] && mkdir -p "$puppeteer_location"
		[ ! -d "$puppeteer_location/Linux-901912" ] && mkdir -p "$puppeteer_location/Linux-901912"
		unzip "$install_dir/application/chrome-linux.zip" -d "$puppeteer_location/Linux-901912" > /dev/null 2>&1
		chmod +x "$puppeteer_location"/Linux-901912/chrome-linux/*
	fi

    check_distribution
	if [[ "$OS" != "sles" && "$OS" != "opensuse-leap" ]]; then
		install-chromium-dependencies
        fi
	
	if [ -d "$puppeteer_location/Linux-901912" ]; then
		say "Chrome package installed successfully"
	fi
}

check_distribution() {
    # Execute custom command if set
    [ -n "$invocation" ] && eval "$invocation"

    # Check and set OS and version
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif command -v lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS="debian"
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        OS="centos" # For older Red Hat, CentOS, etc.
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi

    # Convert OS name to lowercase
    OS=$(echo "$OS" | tr '[:upper:]' '[:lower:]')

    # Determine distribution based on OS
    case "$OS" in
        centos|rhel|ol|almalinux)
            distribution="centos"
            ;;
        sles|opensuse-leap)
            distribution="sles"
            ;;
        debian)
            distribution="debian"
            ;;
	rocky)
	    distribution="rocky"
	    ;;
        kali)
            distribution="kali"
            ;;
        *)
            distribution="ubuntu"
            ;;
    esac

    # Output distribution and version
    echo "Distribution: $distribution"
    echo "Distribution Version: $VER"
}

install-chromium-dependencies() {

    # Execute custom command if set
    [ -n "$invocation" ] && eval "$invocation"

    if [[ "$distribution" == "centos" ]]; then
        yum update -y && yum install -y nss.x86_64 libdrm mesa-libgbm libxshmfence pango.x86_64 \
        libXcomposite.x86_64 libXcursor.x86_64 libXdamage.x86_64 libXext.x86_64 libXi.x86_64 \
        libXtst.x86_64 cups-libs.x86_64 libXScrnSaver.x86_64 libXrandr.x86_64 alsa-lib.x86_64 \
        atk.x86_64 gtk3.x86_64 xorg-x11-fonts-100dpi xorg-x11-fonts-75dpi xorg-x11-utils \
        xorg-x11-fonts-cyrillic xorg-x11-fonts-Type1 xorg-x11-fonts-misc

    elif [[ $distribution == "ubuntu" && $VER == "24.04" ]]; then
        apt-get update && apt-get -y install xvfb libasound2t64 libatk1.0-0t64 libc6 libcairo2 \
        libcups2t64 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc-s1 libgdk-pixbuf2.0-0 \
        libglib2.0-0t64 libgtk-3-0t64 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 \
        libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 \
        libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libnss3 lsb-release \
        xdg-utils wget && rm -rf /var/lib/apt/lists/*

    elif [[ "$distribution" == "debian" ]]; then
        apt-get update && apt-get install -y xvfb gconf-service libasound2 libatk1.0-0 libc6 \
        libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libgconf-2-4 \
        libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 \
        libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 \
        libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation \
        libappindicator1 libnss3 lsb-release xdg-utils wget && rm -rf /var/lib/apt/lists/*

    elif [[ "$distribution" == "kali" ]]; then
        echo "deb http://deb.debian.org/debian buster main" | sudo tee /etc/apt/sources.list.d/debian.list
        # apt-get update && apt-get install -y (other dependencies can be added here)
	
    elif [ "$distribution" == "rocky" ]; then
        sudo dnf update -y && sudo dnf install -y \
        xorg-x11-server-Xvfb libXcomposite libXcursor libXdamage libXext libXfixes \
        libXi libXrandr libXrender libXtst alsa-lib atk glibc cairo cups-libs dbus-libs \
        expat fontconfig libdrm glib2 gtk3 nspr pango libstdc++ libxcb ca-certificates \
        libappindicator-gtk3 nss xdg-utils wget && sudo dnf clean all
		
    else
        apt-get update && apt-get install -y xvfb gconf-service libasound2 libatk1.0-0 libc6 \
        libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libgconf-2-4 \
        libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 \
        libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 \
        libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation \
        libappindicator1 libnss3 lsb-release xdg-utils wget && rm -rf /var/lib/apt/lists/*
    fi
}

update_AI_node_product_json() {
	eval $invocation
    if ! grep -q '"AiService"' "$boldreports_product_json_location"; then
		sed -i '/"InternalAppUrl": {/,/}/ { /"ReportsService":/ s/\("ReportsService":.*\)"/\1",\n    "AiService": ""/ }' "$boldreports_product_json_location"
    fi
}

update_url_in_product_json() {
	eval $invocation
	old_url="http:\/\/localhost\/"
	new_url="$(remove_trailing_slash "$host_url")"

	idp_url="$new_url"
	say "IDP URL - $idp_url"
	
	reports_url="$new_url/reporting"
	say "Reports URL - $reports_url"
	
	reports_service_url="$new_url/reporting/reportservice"
	say "Reports Service URL - $reports_service_url"
	
	sed -i $boldreports_product_json_location -e "s|\"Idp\":.*\",|\"Idp\":\"$idp_url\",|g" -e "s|\"Reports\":.*\",|\"Reports\":\"$reports_url\",|g" -e "s|\"ReportsService\":.*\"|\"ReportsService\":\"$reports_service_url\"|g"
	
	say "Product.json file URLs updated."
}
	
copy_service_files () {
	eval $invocation
	
	cp -a "$1" "$2"
}
	
configure_nginx() {
    local nginx_dir
    local nginx_sites_available_dir="/etc/nginx/sites-available"
    local nginx_sites_enabled_dir="/etc/nginx/sites-enabled"
    local nginx_default_file="$nginx_sites_available_dir/default"
	local domain_name
	local is_https=false

	# Extract domain from host_url
	domain_name=$(echo "$host_url" | sed -E 's|https?://([^/]+).*|\1|')

	# Check if the URL is HTTPS and if the ssl-cert and ssl-key are present (if given)
	if [[ "$host_url" == https://* && "$distribution" = "ubuntu" && -f "$ssl_cert_path" && -f "$ssl_key_path" ]]; then
		is_https=true
	fi
    
    # Execute custom command if set
    [ -n "$invocation" ] && eval "$invocation"

    # CentOS and SLES configuration
    if [[ "$distribution" == "centos" || "$distribution" == "sles" || "$distribution" = "rocky" ]]; then
        nginx_dir="/etc/nginx/conf.d"
        mkdir -p "$nginx_dir"
        echo "Copying Bold Reports Nginx config file for $distribution"

        # Copy and rename the Nginx configuration file
        cp boldreports-nginx-config "$nginx_dir/boldreports-nginx-config.conf"

        # Modify Nginx ports for CentOS version 8
        if [[ "$distribution" == "centos" && "$VER" == 8* ]]; then
            sed -i 's|80 default_server|8080 default_server|g' "/etc/nginx/nginx.conf"
            sed -i 's|[::]:80 default_server|[::]:8080 default_server|g' "/etc/nginx/nginx.conf"
        fi

        # Restart Nginx
        echo "Restarting Nginx service to apply configuration changes"
        systemctl restart nginx

    else
        # For other distributions (likely Debian-based)
        mkdir -p "$nginx_sites_available_dir" "$nginx_sites_enabled_dir"
        echo "Copying Bold Reports Nginx config file"

        # Copy the configuration file
        cp boldreports-nginx-config "$nginx_sites_available_dir/boldreports-nginx-config"
		nginx_config_file="$nginx_sites_available_dir/boldreports-nginx-config"

		if [ "$is_https" = true ]; then
			sed -i 's/#server {/server {/g' "$nginx_config_file"
			sed -i 's/#listen 80;/listen 80;/g' "$nginx_config_file"
			sed -i 's|#server_name[[:space:]]*example\.com;|server_name '"$domain_name"';|g' "$nginx_config_file"
			sed -i 's|#return[[:space:]]*301[[:space:]]*https://example\.com\$request_uri;|return 301 https://'"$domain_name"'\$request_uri;|g' "$nginx_config_file"
			sed -i 's/#}/}/g' "$nginx_config_file"
			sed -i 's/listen[[:space:]]*80[[:space:]]*default_server;/#listen        80 default_server;/g' "$nginx_config_file"
			sed -i 's/#listen 443 ssl;/listen 443 ssl;/g' "$nginx_config_file"
			sed -i "s|#ssl_certificate /path/to/certificate/file/domain.crt;|ssl_certificate $ssl_cert_path;|g" "$nginx_config_file"
            sed -i "s|#ssl_certificate_key /path/to/key/file/domain.key;|ssl_certificate_key $ssl_key_path;|g" "$nginx_config_file"
		fi

        # Backup and remove the default Nginx configuration, if it exists
        if [[ -f "$nginx_default_file" ]]; then
            echo "Taking backup of default Nginx file"
            mv "$nginx_default_file" "$nginx_sites_available_dir/default_backup"
            echo "Removing the default Nginx file"
            rm "$nginx_sites_enabled_dir/default"
        fi

        # Create symbolic link to enable the new configuration
        echo "Creating symbolic link for Bold Reports Nginx config"
        ln -s "$nginx_sites_available_dir/boldreports-nginx-config" "$nginx_sites_enabled_dir/"
    fi

    # Validate and reload Nginx configuration
    echo "Validating the Nginx configuration"
    nginx -t

    echo "Reloading Nginx to apply changes"
    nginx -s reload
}


configure_nginx_for_upgrade(){
	eval $invocation
	is_service_updated_in_config_file=false 

	IFS=$'\n'
	for t in ${!separated_services[@]}; do
    		if ! grep -q "${separated_services[$t]}" "$nginx_config_file_location"; then
  			while true; do
				read -p "Breaking changes: Added a ${t} service that needs to be configured in the Nginx configuration file. If you had installed the application using automatic Nginx configuration during initial installation, choose yes. If not, please complete current installation and manually configure the ${t} service in the Nginx file by referring to the help documentation: https://help.boldreports.com/enterprise-reporting/administrator-guide/installation/deploy-in-linux/upgrade-linux-server/#upgrade-breaking-changes  [yes / no]:  " yn
				case $yn in
					[Yy]* ) configure_service "${separated_services[$t]}" 
						is_service_updated_in_config_file=true; 
						break;;
					[Nn]* ) break;;
					* ) echo "Please answer yes or no.";;
				esac
			done
		fi
	done

	if [ "$is_service_updated_in_config_file" = true ]; then
		validate_nginx_config
	fi
}

validate_nginx_config(){
	eval $invocation
	say "Validating the Nginx configuration"
	nginx -t
	say "Restarting the Nginx to apply the changes"
	systemctl restart nginx
}

configure_service(){
	extracted_location=$(sed -n "/$1/, /}/ p" boldreports-nginx-config)
    	location='\'
	isFirstLine=true

    	for line in $extracted_location;do
    		if [[ "$isFirstLine" == true ]]; then
    			location+="$line"
			isFirstLine=false
    		else
        		location+="\n$line"
		fi
    	done
	
	sed -i "/^\(}\)/ i $location" "$nginx_config_file_location"
}
update_local_service_url() {
	eval $invocation

	local_service_json_file="$configuration_dir/local_service_url.json"

	json_content='{
	  "Idp": "http://localhost:6500",
	  "IdpApi": "http://localhost:6501/api",
	  "Ums": "http://localhost:6502/ums",
	  "Bi": "http://localhost:6504/bi",
	  "BiApi": "http://localhost:6505/bi/api",
	  "BiJob": "http://localhost:6506/bi/jobs",
	  "BiDesigner": "http://localhost:6507/bi/designer",
	  "BiDesignerHelper": "http://localhost:6507/bi/designer/helper",
	  "Etl": "http://localhost:6509",
	  "EtlBlazor": "http://localhost:6509/framework/blazor.server.js",
	  "Ai": "http://localhost:6510/aiservice",
	  "Reports": "http://localhost:6550/reporting",
      "ReportsApi": "http://localhost:6551/reporting/api",
      "ReportsJob": "http://localhost:6552/reporting/jobs",
      "ReportsService": "http://localhost:6553/reporting/reportservice",
      "ReportsViewer": "http://localhost:6554/reporting/viewer"
	}'

	# Check if the JSON file exists
	if [ ! -f "$local_service_json_file" ]; then
	mkdir -p "$configuration_dir"
	echo "$json_content" > "$local_service_json_file"
	say "Local service Json file Created and URL updated"
	fi
}

install_client_libraries () {
	eval $invocation
	bash $install_dir/clientlibrary/boldreports/install-optional.libs.sh install-optional-libs "$user" "$optional_libs"
}

update_optional_lib () {
        if [ -f "$install_dir/optional-lib.txt" ]; then
        eval $invocation
        value=$(<$install_dir/optional-lib.txt)
        echo "$value"
        cd $install_dir/clientlibrary/boldreports
        bash "install-optional.libs.sh" "install-optional-libs" "$user" "$value"
        fi
}

install_phanthomjs () {
	eval $invocation
	mkdir -p $install_dir/application/app_data/reporting/exporthelpers
	mkdir -p $install_dir/clientlibrary/temp
	bash $install_dir/clientlibrary/install-optional.libs.sh install-optional-libs phantomjs
}

is_boldreports_already_installed() {
	systemctl list-unit-files | grep -E "^bold-" > /dev/null 2>&1
	return $?
}

is_service_already_exists() {
	systemctl list-unit-files | grep "$1" > /dev/null 2>&1
	return $?
}

taking_backup(){
    eval $invocation
    say "Started creating backup . . ."
    timestamp="$(date +"%T")"
    backup_file_location=""

    if [ -d "$install_dir" ]; then
        rm -rf $backup_folder/boldreports_backup_*.zip
        backup_file_location=$backup_folder/boldreports_backup_$timestamp.zip
        zip -1 -r $backup_file_location $install_dir 2>&1 | pv -lep -s $(ls -Rl1 $install_dir | egrep -c '^[-/]') > /dev/null
    fi

    say "Backup file name:$backup_file_location"
    say "Backup process completed . . ."
    return $?
}

removing_old_files(){
	eval $invocation
	rm -r $install_dir/application/reporting
	rm -r $install_dir/application/idp
	rm -r $install_dir/application/utilities
	rm -r $install_dir/clientlibrary
	rm -r $install_dir/dotnet
	if [ -d "$install_dir/dotnet-runtime-5.0" ]; then
	rm -r $install_dir/dotnet-runtime-5.0
	fi
	rm -r $install_dir/services
	rm -r $install_dir/Infrastructure
}
	
validate_user() {
	eval $invocation
	if [[ $# -eq 0 ]]; then
		say_err "Please specify the user that manages the service."
		return 1
	fi	
	
	# if grep -q "^$1:" /etc/passwd ;then
		# return 0
	# else
		# say_err "User $1 is not valid"
		# return 1
	# fi
	
	return 0
}

validate_host_url() {
	eval $invocation
	if [[ $# -eq 0 ]]; then
		say_err "Please specify the host URL."
		return 1
	fi	
	
	url_regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
	check_distribution
	if [[ $1 =~ $url_regex ]]; then 
		# Check if the URL is HTTPS
        if [[ $1 == https://* && "$distribution" == "ubuntu" ]]; then
            # Validate SSL certificate and key paths
			if [[ -n "$ssl_cert_path" && ! -n "$ssl_key_path" ]]; then
				say_err "SSL key path is not provided. Both SSL certificate path and SSL key path must be given to configure SSL for the domain."
				return 1
			elif [[ ! -n "$ssl_cert_path" && -n "$ssl_key_path" ]]; then
				say_err "SSL certificate path is not provided. Both SSL certificate path and SSL key path must be given to configure SSL for the domain."
				return 1
			elif [[  -n "$ssl_cert_path" && -n "$ssl_key_path" ]]; then
				if [[ ! -f "$ssl_cert_path" ]]; then
					say_err "SSL certificate file ($ssl_cert_path) does not exist."
					return 1
				fi
				if [[ ! -f "$ssl_key_path" ]]; then
					say_err "SSL key file ($ssl_key_path) does not exist."
					return 1
				fi
			fi
        fi
		return 0
	else
		say_err "Please specify the valid host URL."
		return 1
	fi
}
	
validate_installation_type() {
	eval $invocation
	if  [[ $# -eq 0 ]]; then
		say_err "Please specify the installation type (new or upgrade)."
		return 1
	fi	

	if  [ "$(to_lowercase $1)" != "new" ] && [ "$(to_lowercase $1)" != "upgrade" ]; then
		say_err "Please specify the valid installation type."
		return 1
	fi

	return 0	
}

setup_libdl_symlink(){

    # Execute custom command if set
    [ -n "$invocation" ] && eval "$invocation"

    if [[ "$distribution" == "centos" || "$distribution" == "sles" || "$distribution" == "rocky" ]]; then
       
        lib_path="/usr/lib64"

    else
       
        lib_path="/usr/lib/x86_64-linux-gnu"

    fi

    # Check if libdl.so exists
    if [ -f "$lib_path/libdl.so" ]; then
        echo "libdl.so already exists in $lib_path"
    else
        # Find any versioned libdl.so.* file
        existing_lib=$(find "$lib_path" -maxdepth 1 -name 'libdl.so.*' | head -n 1)
        if [ -n "$existing_lib" ]; then
            echo "Creating symbolic link: $lib_path/libdl.so -> $existing_lib"
            sudo ln -sf "$existing_lib" "$lib_path/libdl.so"
        else
            echo "libdl.so is missing and no versioned libdl.so.* found in $lib_path"
            return 1
        fi
    fi
}
	
reset_proxy_pass_to_default() {
    eval $invocation
    local conf_file=""

	if [ "$distribution" = "ubuntu" ]; then
		conf_file="/etc/nginx/sites-available/boldreports-nginx-config"
	elif [ "$distribution" = "centos" ] || [ "$distribution" = "sles" ] || [ "$distribution" = "rocky" ]; then
		conf_file="/etc/nginx/conf.d/boldreports-nginx-config"
	else
		say_err "Unsupported distribution for nginx config: $distribution"
		return 1
	fi

    [ ! -f "$conf_file" ] && {
        say "Config file not found: $conf_file → skipping"
        return 0
    }

	sed -i -E '
		/_framework\/blazor\.server\.js/ {
			s|(proxy_pass[ \t]+http://localhost:6509).*|proxy_pass         http://localhost:6509/_framework/blazor.server.js;|g
		}

		/6509/ {
			/_framework\/blazor\.server\.js/! {
				s|(proxy_pass[ \t]+http://localhost:6509).*|proxy_pass         http://localhost:6509/;|g
			}
		}

		/6509/! {
			s|(proxy_pass[ \t]+http://localhost:[0-9]+).*|\1;|g
			s|(proxy_pass[ \t]+http://localhost:[0-9]+)/[ \t]*;|\1;|g
		}
	' "$conf_file"

	local_service_json_file="$configuration_dir/local_service_url.json"

	json_content='{
	  "Idp": "http://localhost:6500",
	  "IdpApi": "http://localhost:6501/api",
	  "Ums": "http://localhost:6502/ums",
	  "Bi": "http://localhost:6504/bi",
	  "BiApi": "http://localhost:6505/bi/api",
	  "BiJob": "http://localhost:6506/bi/jobs",
	  "BiDesigner": "http://localhost:6507/bi/designer",
	  "BiDesignerHelper": "http://localhost:6507/bi/designer/helper",
	  "Etl": "http://localhost:6509",
	  "EtlBlazor": "http://localhost:6509/framework/blazor.server.js",
	  "Ai": "http://localhost:6510/aiservice",
	  "Reports": "http://localhost:6550/reporting",
      "ReportsApi": "http://localhost:6551/reporting/api",
      "ReportsJob": "http://localhost:6552/reporting/jobs",
      "ReportsService": "http://localhost:6553/reporting/reportservice",
      "ReportsViewer": "http://localhost:6554/reporting/viewer"
	}'

	echo "$json_content" > "$local_service_json_file"

	restart_boldreports_services

    return 0
}
	
install_boldreports() {
	eval $invocation
    local download_failed=false
    local asset_name=''
    local asset_relative_path=''
	check_min_reqs

	if [[ "$?" != "0" ]]; then
		return 1
	fi
	
	validate_user $user
	if [[ "$?" != "0" ]]; then
		return 1
	fi 
	
	validate_installation_type $installation_type
	if [[ "$?" != "0" ]]; then
		return 1
	fi
	validate_host_url $host_url
	if [[ "$?" != "0" ]]; then
		return 1
	fi
			
	if is_boldreports_already_installed; then
		####### Bold Reports Upgrade Install######
		
		if [ "$(to_lowercase $installation_type)" = "new" ]; then
			say_err "Bold Reports already present in this machine. Terminating the installation process..."
			return 1
		fi
	
        say "Bold Reports already present in this machine."
		stop_boldreports_services
		sleep 5
		if taking_backup; then		
			removing_old_files
			
			copy_files_to_installation_folder
			
			update_url_in_product_json
   
			update_AI_node_product_json
			
			update_local_service_url
			
			find "$services_dir" -type f -name "*.service" -print0 | xargs -0 sed -i "s|www-data|$user|g"
			copy_service_files "$services_dir/." "$system_dir"
			
			chmod +x "$dotnet_dir/dotnet"
			
			[ ! -d "$puppeteer_location/Linux-901912" ] && chrome_package_installation

			setup_libdl_symlink
			
			chown -R "$user" "$install_dir"
			
			enable_boldreports_services
			start_boldreports_services

			if [ -f "$nginx_config_file_location" ]; then
				configure_nginx_for_upgrade
			else
				say "Breaking changes: Added new services that need to be manually configured in the Nginx configuration file. Please refer to the help documentation for more information: https://help.boldreports.com/enterprise-reporting/administrator-guide/installation/deploy-in-linux/upgrade-linux-server/#upgrade-breaking-changes"
			fi
			
			sleep 5
			
			reset_proxy_pass_to_default

			update_optional_lib
            restart_boldreports_services
			
			status_boldreports_services
			say "Bold Reports upgraded successfully!!!"
			
			return 0
		else
			return 1
		fi
    else
		####### Bold Reports Fresh Install######
	
		if [ "$installation_type" = "upgrade" ]; then
			say_err "Bold Reports is not present in this machine. Terminating the installation process..."
			say_err "Please do a fresh install."
			return 1
		fi
	
		mkdir -p "$install_dir"    
		copy_files_to_installation_folder
		update_url_in_product_json
		update_local_service_url
		find "$services_dir" -type f -name "*.service" -print0 | xargs -0 sed -i "s|www-data|$user|g"
		systemctl daemon-reload
		if [ ! -z "$lic_key" ] || [ ! -z "$db_type" ] || [ ! -z "$email" ]; then
			find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/DOTNET_PRINT_TELEMETRY_MESSAGE/a Environment=BOLD_SERVICES_UNLOCK_KEY='$lic_key''
			find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_UNLOCK_KEY/a Environment=BOLD_SERVICES_HOSTING_ENVIRONMENT=k8s'
			find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_HOSTING_ENVIRONMENT/a Environment=BOLD_SERVICES_DB_TYPE='$db_type''
			find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_DB_TYPE/a Environment=BOLD_SERVICES_DB_PORT='$db_port''
			find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_DB_PORT/a Environment=BOLD_SERVICES_DB_HOST='$db_host''
			find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_DB_HOST/a Environment=BOLD_SERVICES_POSTGRESQL_MAINTENANCE_DB='$maintain_db''
			find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_POSTGRESQL_MAINTENANCE_DB/a Environment=BOLD_SERVICES_DB_USER='$db_user''
			find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_DB_USER/a Environment=BOLD_SERVICES_DB_PASSWORD='$db_pwd''
			find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_DB_PASSWORD/a Environment=BOLD_SERVICES_DB_NAME='$db_name''
			find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_DB_NAME/a Environment=BOLD_SERVICES_DB_ADDITIONAL_PARAMETERS='$add_parameters''
			find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_DB_ADDITIONAL_PARAMETERS/a Environment=BOLD_SERVICES_USER_EMAIL='$email''
			find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_USER_EMAIL/a Environment=BOLD_SERVICES_USER_PASSWORD='$epwd''
			if [ ! -z "$main_logo" ]; then
				find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_USER_PASSWORD/a Environment=BOLD_SERVICES_BRANDING_MAIN_LOGO='$main_logo''
				find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_BRANDING_MAIN_LOGO/a Environment=BOLD_SERVICES_BRANDING_LOGIN_LOGO='$login_logo''
				find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_BRANDING_LOGIN_LOGO/a Environment=BOLD_SERVICES_BRANDING_EMAIL_LOGO='$email_logo''
				find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_BRANDING_EMAIL_LOGO/a Environment=BOLD_SERVICES_BRANDING_FAVICON='$favicon''
				find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_BRANDING_FAVICON/a Environment=BOLD_SERVICES_BRANDING_FOOTER_LOGO='$footer_logo''
				find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_BRANDING_FOOTER_LOGO/a Environment=BOLD_SERVICES_SHOW_COPY_RIGHT_INFO='$show_copyright_info''
				find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_SHOW_COPY_RIGHT_INFO/a Environment=BOLD_SERVICES_SHOW_POWERED_BY_SYNCFUSION='$show_copyright_info''
			fi
			if [ ! -z "$site_name" ]; then
				find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_BRANDING_FOOTER_LOGO/a Environment=BOLD_SERVICES_SITE_NAME='$site_name''
				find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_SITE_NAME/a Environment=BOLD_SERVICES_SITE_IDENTIFIER='$site_identifier''
				find "$services_dir" -type f -name "bold-ums-web.service" -print0 | xargs -0 sed -i '/BOLD_SERVICES_SITE_IDENTIFIER/a Environment=BOLD_SERVICES_USE_SITE_IDENTIFIER='$use_siteidentifier''
			fi
		fi
		copy_service_files "$services_dir/." "$system_dir"
		if [ ! -z "$optional_libs" ]; then
   			install_client_libraries
		fi
		#install_phanthomjs
		
		chmod +x "$dotnet_dir/dotnet"
		
		chrome_package_installation
		setup_libdl_symlink
		
		chown -R "$user" "$install_dir"
		
		sleep 5
		
		enable_boldreports_services
		start_boldreports_services
		
		sleep 5
	
		status_boldreports_services
		
		if [ "$can_configure_nginx" = true ]; then
			configure_nginx
		fi
		say "Bold Reports installation completed!!!"
		return 0
    fi
	
	#zip_path="$(mktemp "$temporary_file_template")"
    #say_verbose "Zip path: $zip_path"
	
	# Failures are normal in the non-legacy case for ultimately legacy downloads.
    # Do not output to stderr, since output to stderr is considered an error.
    #say "Downloading primary link $download_link"
	
	# The download function will set variables $http_code and $download_error_msg in case of failure.
    #http_code=""; download_error_msg=""
    #download "$download_link" "$zip_path" 2>&1 || download_failed=true
    #primary_path_http_code="$http_code"; primary_path_download_error_msg="$download_error_msg"
	
	#say "Extracting zip from $download_link"
	
	#extract_boldbi_package "$zip_path" "$install_dir" || return 1
}

install_boldreports
