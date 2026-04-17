#!/bin/bash

app_data_location="/application/app_data"
puppeteer_location="$app_data_location/reporting/exporthelpers/puppeteer"
configuration_path="$app_data_location/configuration"

if [ -d "$app_data_location/configuration" ]; then
  echo "Configuration directory exists"
else
  mkdir -p "$app_data_location/configuration" && chmod 777 "$app_data_location/configuration"
fi

local_service_json_file="$configuration_path/local_service_url.json"


if [ ! -f "$local_service_json_file" ]; then

  if [ "$BOLD_SERVICES_HOSTING_ENVIRONMENT" = "ecs_multi_container" ]; then
    # ECS multi-container (provide placeholders for you to modify)
    json_content=$(cat <<EOF
{
  "Idp": "http://id-web-service.boldbi-ns",
  "IdpApi": "http://id-api-service.boldbi-ns/api",
  "Ums": "http://id-ums-service.boldbi-ns/ums",
  "Bi": "http://bi-web-service.boldbi-ns/bi",
  "BiApi": "http://bi-api-service.boldbi-ns/bi/api",
  "BiJob": "http://bi-jobs-service.boldbi-ns/bi/jobs",
  "BiDesigner": "http://bi-designer-service.boldbi-ns/bi/designer",
  "BiDesignerHelper": "http://bi-designer-service.boldbi-ns/bi/designer/helper",
  "Etl": "http://etl-service.boldbi-ns",
  "EtlBlazor": "http://etl-service.boldbi-ns/framework/blazor.server.js",
  "Ai": "http://ai-service.boldbi-ns/aiservice",
  "Reports": "http://reports-web-service.boldreports-ns/reporting",
  "ReportsApi": "http://reports-api-service.boldreports-ns/reporting/api",
  "ReportsJob": "http://reports-jobs-service.boldreports-ns/reporting/jobs",
  "ReportsService": "http://reports-designer-service.boldreports-ns/reporting/reportservice",
  "ReportsViewer": "http://reports-viewer-service.boldreports-ns/reporting/viewer"
}
EOF
)

  elif [ "$DEPLOY_MODE" = "docker_multi_container" ]; then
    # Docker multi-container (upstream container names)
    json_content=$(cat <<EOF
{
  "Idp": "http://id-web",
  "IdpApi": "http://id-api/api",
  "Ums": "http://id-ums/ums",
  "Bi": "http://bi-web/bi",
  "BiApi": "http://bi-api/bi/api",
  "BiJob": "http://bi-jobs/bi/jobs",
  "BiDesigner": "http://bi-dataservice/bi/designer",
  "BiDesignerHelper": "http://bi-dataservice/bi/designer/helper",
  "Etl": "http://reports-etl",
  "EtlBlazor": "http://reports-etl/framework/blazor.server.js",
  "Ai": "http://bold-ai/aiservice",
  "Reports": "http://reports-web/reporting",
  "ReportsApi": "http://reports-api/reporting/api",
  "ReportsJob": "http://reports-jobs/reporting/jobs",
  "ReportsService": "http://reports-reportservice/reporting/reportservice",
  "ReportsViewer": "http://reports-viewer/reporting/viewer"
}
EOF
)

  elif [ "$BOLD_SERVICES_HOSTING_ENVIRONMENT" = "k8s" ]; then
    # Default: Kubernetes ClusterIP services
    json_content=$(cat <<EOF
{
  "Idp": "http://id-web-service:6000",
  "IdpApi": "http://id-api-service:6001/api",
  "Ums": "http://id-ums-service:6002/ums",
  "Bi": "http://bi-web-service:6004/bi",
  "BiApi": "http://bi-api-service:6005/bi/api",
  "BiJob": "http://bi-jobs-service:6006/bi/jobs",
  "BiDesigner": "http://bi-dataservice-service:6007/bi/designer",
  "BiDesignerHelper": "http://bi-dataservice-service:6007/bi/designer/helper",
  "Etl": "http://bold-etl-service:6009",
  "EtlBlazor": "http://bold-etl-service:6009/framework/blazor.server.js",
  "Ai": "http://bold-ai-service:6010/aiservice",
  "Reports": "http://reports-web-service:6550/reporting",
  "ReportsApi": "http://reports-api-service:6551/reporting/api",
  "ReportsJob": "http://reports-jobs-service:6552/reporting/jobs",
  "ReportsService": "http://reports-reportservice-service:6553/reporting/reportservice",
  "ReportsViewer": "http://reports-viewer-service:6554/reporting/viewer"
}
EOF
)
  fi

  # Write the content
  echo "$json_content" > "$local_service_json_file"
  echo "Created: $local_service_json_file"
else
  echo "$local_service_json_file already exists. Skipping creation."
fi

dotnet appdatafiles/MoveSharedFiles/MoveSharedFiles.dll

    if ! grep -q '"AiService"' "/application/app_data/configuration/product.json"; then
		sed -i '/"InternalAppUrl": {/,/}/ { /"ReportsService":/ s/\("ReportsService":.*\)"/\1",\n    "AiService": ""/ }' "/application/app_data/configuration/product.json"
    fi

if [ ! -d "$puppeteer_location/Linux-901912" ]; then
	[ ! -d "$app_data_location/reporting" ] && mkdir -p "$app_data_location/reporting"
	[ ! -d "$app_data_location/reporting/exporthelpers" ] && mkdir -p "$app_data_location/reporting/exporthelpers"
	[ ! -d "$puppeteer_location" ] && mkdir -p "$puppeteer_location"

	dotnet "/application/utilities/adminutils/Syncfusion.Server.Commands.Utility.dll" "installpuppeteer" -path "$puppeteer_location"
fi

if [ -d "$puppeteer_location/Linux-901912" ]; then
	## Removing PhantomJS
	[ -f "$app_data_location/reporting/exporthelpers/phantomjs" ] && rm -rf "$app_data_location/reporting/exporthelpers/phantomjs"
fi

dotnet Syncfusion.Server.IdentityProvider.Core.dll --urls=http://0.0.0.0:80