#!/bin/bash
#!/bin/bash
# command to run this file
# bash install-option-lib.sh install-optional-libs {podname}
command=$1
podname=$2
root_path=$3
installoptionlibs="install-optional-libs"
root_path="/application"
entrypath=$root_path/app_data/optional-libs
clientlibrary=$entrypath/boldreports
assemblypath=$clientlibrary/clientlibraries

if [[ -n "${INSTALL_OPTIONAL_LIBS:-}" ]]; then
    echo -e "${Green}info:${NC} Optional libs list obtained from environment variable."
    arguments="$INSTALL_OPTIONAL_LIBS"
else
    # If environment variable not set, wait and retry checking.
    count=0
    file_found=false
    while [[ $count -lt 3 ]]; do
        if [[ -f "$entrypath/optional-libs.txt" ]]; then
            arguments=$(<"$entrypath/optional-libs.txt")
            file_found=true
            break
        else
            sleep 10
            ((count++))
        fi
    done

    # If file is still missing after 3 retries, show a warning message
    if [[ "$file_found" = false ]]; then
        echo -e "${Yellow}Warning:${NC} optional-libs.txt not found and INSTALL_OPTIONAL_LIBS is not set"
    fi
fi

 # check empty assembly names
        if [ -z "$podname" ]
        then
        echo "No Optional Libraries were chosen."
        else

        # split assembly name into array

        IFS=', ' read -r -a assmeblyarguments <<< "$podname"
        assembly=("mysql" "oracle" "postgresql" "snowflake" "googlebigquery")
        directories=("api" "jobs" "web" "viewer" "reportservice")
        mysqlassemblies=""
        postgresqlassemblies=""
        oracleassemblies=""
        snowflakeassemblies=""
		googlebigqueryassemblies=""
        serverpath=$root_path/reporting
        apijson="${serverpath}/api/appsettings.Production.json;"
        jobsjson="${serverpath}/jobs/appsettings.Production.json;"
        webjson="${serverpath}/web/appsettings.Production.json;"
        viewerjson="${serverpath}/viewer/appsettings.Production.json;"
        servicejson="${serverpath}/reportservice/appsettings.json"
        jsonfiles="$apijson$jobsjson$webjson$viewerjson$servicejson"
        nonexistassembly=()




# create invalid assembly array
for element in "${assmeblyarguments[@]}"
do
    if [[ ! " ${assembly[@]} " =~ " ${element} " ]]; then
    nonexistassembly+=("$element")
    fi
done

# check non exist assembly count
if [ ${#nonexistassembly[@]} -ne 0 ]; then
echo "The below optional library names do not exist. Please enter valid library names."

for element in "${nonexistassembly[@]}"
do
echo "$element"
done

else
for element in "${assmeblyarguments[@]}"
do
case $element in
"mysql")
mysqlassemblies="${element}=BoldReports.Data.MySQL;MemSQL;MariaDB;"
    for dirname in "${directories[@]}"
    do
        pluginpath=$root_path/reporting/$dirname
        cp -rf $assemblypath/BoldReports.Data.MySQL.dll $pluginpath
        cp -rf $assemblypath/MySqlConnector.dll $pluginpath
    done
echo "mysql libraries are installed"
;;
"oracle")
oracleassemblies="${element}=BoldReports.Data.Oracle;"
    for dirname in "${directories[@]}"
    do
        pluginpath=$root_path/reporting/$dirname
        cp -rf $assemblypath/BoldReports.Data.Oracle.dll $pluginpath
        cp -rf $assemblypath/Oracle.ManagedDataAccess.dll $pluginpath
    done
echo "oracle libraries are installed"
;;
"postgresql")
postgresqlassemblies="${element}=BoldReports.Data.PostgreSQL;"
    for dirname in "${directories[@]}"
    do
        pluginpath=$root_path/reporting/$dirname
        cp -rf $assemblypath/BoldReports.Data.PostgreSQL.dll $pluginpath
        cp -rf $assemblypath/Npgsql.dll $pluginpath
    done

echo "postgresql libraries are installed"
;;
"snowflake")
snowflakeassemblies="${element}=BoldReports.Data.Snowflake;Snowflake.Data;"
    for dirname in "${directories[@]}"
    do
        pluginpath=$root_path/reporting/$dirname
        cp -rf $assemblypath/BoldReports.Data.Snowflake.dll $pluginpath
        cp -rf $assemblypath/Snowflake.Data.dll $pluginpath
        cp -rf $assemblypath/Mono.Unix.dll $pluginpath
    done
echo "snowflake libraries are installed"
;;
"googlebigquery")
googlebigqueryassemblies="${element}=BoldReports.Data.GoogleBigQuery;"
    for dirname in "${directories[@]}"
    do
	pluginpath=$root_path/reporting/$dirname
yes | cp -rpf $assemblypath/BoldReports.Data.GoogleBigQuery.dll $pluginpath
yes | cp -rpf $assemblypath/Google.Cloud.BigQuery.V2.dll $pluginpath
yes | cp -rpf $assemblypath/Google.Api.Gax.dll $pluginpath
yes | cp -rpf $assemblypath/Google.Api.Gax.Rest.dll $pluginpath
yes | cp -rpf $assemblypath/Google.Apis.dll $pluginpath
yes | cp -rpf $assemblypath/Google.Apis.Auth.dll $pluginpath
yes | cp -rpf $assemblypath/Google.Apis.Bigquery.v2.dll $pluginpath
yes | cp -rpf $assemblypath/Google.Apis.Core.dll $pluginpath
done
echo "googlebigquery libraries are installed"
;;
esac
done

# add client libraries in json files
clientLibraries="$mysqlassemblies$oracleassemblies$postgresqlassemblies$snowflakeassemblies$googlebigqueryassemblies"
dotnet $clientlibrary/clientlibraryutility/ClientLibraryUtil.dll $clientLibraries $jsonfiles
echo "client libraries are updated"

fi
fi
