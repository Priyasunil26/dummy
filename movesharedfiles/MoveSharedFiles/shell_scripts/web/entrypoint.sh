#!/bin/bash

commonPath=/application/app_data/optional-libs
clientLibraryPath=$commonPath/boldreports
if [ -d "$clientLibraryPath" ]; then
    bash $clientLibraryPath/install-optional.libs.sh install-optional-libs web
    echo "Clientlibrary installed from boldreports folder"
else
    bash $commonPath/reporting/install-optional.libs.sh install-optional-libs web
    echo  "Clientlibrary installed from reporting folder"
fi

setup_libdl_symlink(){

    # Execute custom command if set
    [ -n "$invocation" ] && eval "$invocation"

       
    lib_path=$(case "$(uname -m)" in x86_64) echo "/usr/lib/x86_64-linux-gnu";; aarch64|arm64) echo "/usr/lib/aarch64-linux-gnu";; *) echo "Unsupported arch" >&2; exit 1;; esac)


    # Check if libdl.so exists
    if [ -f "$lib_path/libdl.so" ]; then
        echo "libdl.so already exists in $lib_path"
    else
        # Find any versioned libdl.so.* file
        existing_lib=$(find "$lib_path" -maxdepth 1 -name 'libdl.so.*' | head -n 1)
        if [ -n "$existing_lib" ]; then
            echo "Creating symbolic link: $lib_path/libdl.so -> $existing_lib"
            ln -sf "$existing_lib" "$lib_path/libdl.so"
        else
            echo "libdl.so is missing and no versioned libdl.so.* found in $lib_path"
            return 1
        fi
    fi
}

move_chromium_to_destination() {
    chromium_path="/usr/bin/chromium"
    chrome_destination="/application/app_data/reporting/exporthelpers/puppeteer/Linux-901912/chrome-linux"

    if [ -f "$chromium_path" ]; then
        [ -f "$chrome_destination/chrome" ] && rm -f "$chrome_destination/chrome"
        cp "$chromium_path" "$chrome_destination/chrome"
        chmod +x "$chrome_destination/chrome"
        echo "Chromium package moved and renamed to 'chrome' successfully"
    fi
}

if [ "$(uname -m)" = "aarch64" ]; then
    move_chromium_to_destination
fi

setup_libdl_symlink

dotnet Syncfusion.Server.Reports.dll --urls=http://0.0.0.0:80