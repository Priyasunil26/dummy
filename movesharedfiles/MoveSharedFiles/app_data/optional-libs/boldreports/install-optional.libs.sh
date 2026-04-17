#!/bin/bash

# Usage: bash install-option-lib.sh install-optional-libs <podname> [root_path]

command=$1
podname=$2
root_path=${3:-/application}
installoptionlibs="install-optional-libs"

# Logging functions
log_info()    { echo -e "[INFO] $1"; }
log_warn()    { echo -e "[WARN] $1"; }
log_error()   { echo -e "[ERROR] $1"; }

# Validate pod name
if [ -z "$podname" ]; then
    log_error "Pod name is empty. Provide one of: api, web, jobs, or reportservice"
    exit 1
fi

# Validate command
if [ -z "$command" ]; then
    log_error "Command is empty. Use: install-optional-libs"
    exit 1
elif [ "$command" != "$installoptionlibs" ]; then
    log_error "Invalid command '$command'. Expected: install-optional-libs"
    exit 1
fi

entrypath="$root_path/app_data/optional-libs"
clientlibrary="$entrypath/boldreports"
assemblypath="$clientlibrary/clientlibraries"

# Read optional libraries from file
if ! arguments=$(<"$entrypath/optional-libs.txt"); then
    log_error "Unable to read optional-libs.txt from $entrypath"
    exit 1
fi

if [ -z "$arguments" ]; then
    log_warn "No optional library names found in optional-libs.txt"
    exit 0
fi

IFS=', ' read -r -a assmeblyarguments <<< "$arguments"
assembly_list=("mysql" "oracle" "postgresql" "snowflake" "googlebigquery" "mongodb")

# Determine pod-specific JSON path
podpath="$root_path/reporting/$podname"
jsonfilepath="$podpath/appsettings.Production.json"
[ "$podname" = "reportservice" ] && jsonfilepath="$podpath/appsettings.json"

# Track invalid entries
nonexistassembly=()
validassembly=()

for element in "${assmeblyarguments[@]}"; do
    if [[ ! " ${assembly_list[*]} " =~ " $element " ]]; then
        nonexistassembly+=("$element")
    else
        validassembly+=("$element")
    fi
done

if [[ ${#nonexistassembly[@]} -ne 0 ]]; then
    log_warn "Some optional libraries were not recognized and will be skipped:"
    for element in "${nonexistassembly[@]}"; do
        echo " - $element"
    done
    log_info "Available optional libraries: ${assembly_list[*]}"
fi

if [[ ${#validassembly[@]} -eq 0 ]]; then
    log_error "No valid optional libraries found to install. Exiting."
    exit 1
fi

pluginpath="$root_path/reporting/$podname"

# Initialize assembly strings
mysqlassemblies=""
postgresqlassemblies=""
oracleassemblies=""
snowflakeassemblies=""
googlebigqueryassemblies=""
mongodbassemblies=""

# Install valid assemblies
for element in "${validassembly[@]}"; do
    case $element in
    "mysql")
        mysqlassemblies="${element}=BoldReports.Data.MySQL;MemSQL;MariaDB;"
        cp -rpf "$assemblypath/BoldReports.Data.MySQL.dll" "$pluginpath"
        cp -rpf "$assemblypath/MySqlConnector.dll" "$pluginpath"
        log_info "Installed MySQL libraries"
        ;;
    "oracle")
        oracleassemblies="${element}=BoldReports.Data.Oracle;"
        cp -rpf "$assemblypath/BoldReports.Data.Oracle.dll" "$pluginpath"
        cp -rpf "$assemblypath/Oracle.ManagedDataAccess.dll" "$pluginpath"
        log_info "Installed Oracle libraries"
        ;;
    "postgresql")
        postgresqlassemblies="${element}=BoldReports.Data.PostgreSQL;"
        cp -rpf "$assemblypath/BoldReports.Data.PostgreSQL.dll" "$pluginpath"
        cp -rpf "$assemblypath/Npgsql.dll" "$pluginpath"
        log_info "Installed PostgreSQL libraries"
        ;;
    "snowflake")
        snowflakeassemblies="${element}=BoldReports.Data.Snowflake;Snowflake.Data;"
        cp -rpf "$assemblypath/BoldReports.Data.Snowflake.dll" "$pluginpath"
        cp -rpf "$assemblypath/Snowflake.Data.dll" "$pluginpath"
        cp -rpf "$assemblypath/Mono.Unix.dll" "$pluginpath"
        log_info "Installed Snowflake libraries"
        ;;
    "googlebigquery")
        googlebigqueryassemblies="${element}=BoldReports.Data.GoogleBigQuery;"
        cp -rpf "$assemblypath/BoldReports.Data.GoogleBigQuery.dll" "$pluginpath"
        cp -rpf "$assemblypath/Google.Cloud.BigQuery.V2.dll" "$pluginpath"
        cp -rpf "$assemblypath/Google.Api.Gax.dll" "$pluginpath"
        cp -rpf "$assemblypath/Google.Api.Gax.Rest.dll" "$pluginpath"
        cp -rpf "$assemblypath/Google.Apis.dll" "$pluginpath"
        cp -rpf "$assemblypath/Google.Apis.Auth.dll" "$pluginpath"
        cp -rpf "$assemblypath/Google.Apis.Bigquery.v2.dll" "$pluginpath"
        cp -rpf "$assemblypath/Google.Apis.Core.dll" "$pluginpath"
        log_info "Installed Google BigQuery libraries"
        ;;
    "mongodb")
        mongodbassemblies="${element}=BoldReports.Data.MongoDB;"
        cp -rpf "$assemblypath/BoldReports.Data.MongoDB.dll" "$pluginpath"
        cp -rpf "$assemblypath/MongoDB.Bson.dll" "$pluginpath"
        cp -rpf "$assemblypath/MongoDB.Driver.dll" "$pluginpath"
        cp -rpf "$assemblypath/MongoDB.Driver.Core.dll" "$pluginpath"
        cp -rpf "$assemblypath/MongoDB.Libmongocrypt.dll" "$pluginpath"
        cp -rpf "$assemblypath/DnsClient.dll" "$pluginpath"
        log_info "Installed MongoDB libraries"
        ;;
    esac
done

# Prepare final string and call .NET tool
clientLibraries="$mysqlassemblies$oracleassemblies$postgresqlassemblies$snowflakeassemblies$googlebigqueryassemblies$mongodbassemblies"
log_info "Updating appsettings file with installed libraries..."
if dotnet "$clientlibrary/clientlibraryutility/ClientLibraryUtil.dll" "$clientLibraries" "$jsonfilepath"; then
    log_info "Client libraries successfully updated in $jsonfilepath"
else
    log_error "Failed to update client libraries in $jsonfilepath"
    exit 1
fi