#!/bin/bash
set -e
set -o pipefail

function usage() {
    cat <<EOF
Usage: dwdeploy [-z cartridges path] [-v code version] [-h webdav host] [-u webdav user] [-p webdav password] [-c webdav certificate] [-x webdav cert password] [-d debug mode] [-? help]
    -z  the path of the zip archive of cartridges to transfer
    -v  the code version name to apply to the payload
    -h  the webdav host
    -u  the webdav user
    -p  the webdav password
    -c  the webdav certificate
    -x  the password/key for the webdav certificate
    -d  debug
    -?  help
EOF
}

MISSING_ARG=false

# Get our options
while getopts 'z:v:h:u:p:dc:x:' opt; do
  case "$opt" in
    z )  ZIP=${OPTARG} ;;
    v )  CODE_VERSION=${OPTARG} ;;
    h )  HOST=${OPTARG} ;;
    u )  USER=${OPTARG} ;;
    p )  PASSWORD=${OPTARG} ;;
    d )  DEBUG=true ;;
    c )  CERT=${OPTARG} ;;
    x )  CERT_PASSWORD=${OPTARG} ;;
    \?)  usage ;;
  esac
done

shift "$((OPTIND - 1))"

if [ -z "$ZIP" ]; then
    echo "-z (ZIP) is required"
    MISSING_ARG=true
fi

if [ -z "$HOST" ]; then
    echo "-h (HOST) is required"
    MISSING_ARG=true
fi

if [ -z "$USER" ]; then
    echo "-u (USER) is required"
    MISSING_ARG=true
fi

if [ -z "$PASSWORD" ]; then
    echo "-p (PASSWORD) is required"
    MISSING_ARG=true
fi

if [ -z "$CODE_VERSION" ]; then
    echo "-v is required to specify the code version"
    MISSING_ARG=true
fi

if [ -z "$MISSING_ARG" ]; then
    exit 1
fi

if [ -z "$CERT" ]; then
    if [ "$DEBUG" ]; then
        curl --verbose -u "${USER}:${PASSWORD}" -X MKCOL "https://${HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}"
    fi

    # for staging deployments because it requires 2 factor auth using keys
    response=$(curl --write-out %'{'http_code'}' --silent --output /dev/null -u "${USER}:${PASSWORD}" -X MKCOL "https://${HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}")

    if [ "$response" -eq 201 ]; then
        curl -u "${USER}:${PASSWORD}" -T "${ZIP}" "https://${HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}/cartridges.zip"
        curl -u "${USER}:${PASSWORD}" --data "method=UNZIP" "https://${HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}/cartridges.zip"
        curl -u "${USER}:${PASSWORD}" -X DELETE "https://${HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}/cartridges.zip"
    else
        echo "Unauthorized Request. Check your username and password"
        exit 1
    fi
else
    # for development/sandbox deployments where 2 factor auth using keys is not required
    response=$(curl --write-out %'{'http_code'}' --silent --output /dev/null --cert "${CERT}:${CERT_PASSWORD}" -k -u "${USER}:${PASSWORD}" -X MKCOL "https://${HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}")

    if [ "$response" -eq 201 ]; then
        curl --cert "${CERT}:${CERT_PASSWORD}" -k -u "${USER}:${PASSWORD}" -T "${ZIP}" "https://${HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}/cartridges.zip"
        curl --cert "${CERT}:${CERT_PASSWORD}" -k -u "${USER}:${PASSWORD}" --data "method=UNZIP" "https://${HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}/cartridges.zip"
        curl --cert "${CERT}:${CERT_PASSWORD}" -k -u "${USER}:${PASSWORD}" -X DELETE "https://${HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}/cartridges.zip"
    else
        echo "Unauthorized Request. Check your username and password"
        exit 1
    fi
fi
