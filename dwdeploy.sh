#!/bin/bash
set -e
set -o pipefail

# Get our options
while getopts 'zvhupdcx:' OPTION; do
  case "$OPTION" in
    z)
      ZIP=${OPTARG}
      ;;
    h)
      WEBDAV_HOST=${OPTARG}
      ;;
    u)
      WEBDAV_USER=${OPTARG}
      ;;
    p)
      WEBDAV_PASS=${OPTARG}
      ;;
    v)
      CODE_VERSION=${OPTARG}
      ;;
    d)
      DEBUG=${OPTARG}
      ;;
    c)
      CERT=${OPTARG}
      ;;
    x)
      CERT_PASS=${OPTARG}
      ;;
  esac
done

if [ -z "${ZIP}" ]; then
    fail "You need to set `z` to a .zip of your cartridges"
fi

if [ -z "${WEBDAV_HOST}" ]; then
    fail "You need to set `hostname` to the hostname of the Demandware server"
fi

if [ -z "${WEBDAV_USER}" ]; then
    fail "You need to set `username` to the webdav user"
fi

if [ -z "${WEBDAV_PASS}" ]; then
    fail "You need to set `password` to the webdav user's password"
fi

if [ -z "${CODE_VERSION}" ]; then
    fail "You need to set `password` to the webdav user's password"
fi

if [ -z "${CERT}" ]; then
    if [ "${DEBUG}" ]; then
        curl --verbose -u ${WEBDAV_USER}:${WEBDAV_PASS} -X MKCOL "https://${WEBDAV_HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}"
    fi

    response=$(curl --write-out %{http_code} --silent --output /dev/null -u ${WEBDAV_USER}:${WEBDAV_PASS} -X MKCOL "https://${WEBDAV_HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}")

    if [ $response -eq 201 ]; then
        curl -u ${WEBDAV_USER}:${WEBDAV_PASS} -T ${ZIP} "https://${WEBDAV_HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}/cartridges.zip"
        curl -u ${WEBDAV_USER}:${WEBDAV_PASS} --data "method=UNZIP" "https://${WEBDAV_HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}/cartridges.zip"
        curl -u ${WEBDAV_USER}:${WEBDAV_PASS} -X DELETE "https://${WEBDAV_HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}/cartridges.zip"
    else
        fail "Unauthorized Request. Check your username and password"
    fi
else
    response=$(curl --write-out %{http_code} --silent --output /dev/null --cert ${CERT}:${CERT_PASS} -k -u ${WEBDAV_USER}:${WEBDAV_PASS} -X MKCOL "https://${WEBDAV_HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}")

    if [ $response -eq 201 ]; then
        curl --cert ${CERT}:${CERT_PASS} -k -u ${WEBDAV_USER}:${WEBDAV_PASS} -T ${ZIP} "https://${WEBDAV_HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}/cartridges.zip"
        curl --cert ${CERT}:${CERT_PASS} -k -u ${WEBDAV_USER}:${WEBDAV_PASS} --data "method=UNZIP" "https://${WEBDAV_HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}/cartridges.zip"
        curl --cert ${CERT}:${CERT_PASS} -k -u ${WEBDAV_USER}:${WEBDAV_PASS} -X DELETE "https://${WEBDAV_HOST}/on/demandware.servlet/webdav/Sites/Cartridges/${CODE_VERSION}/cartridges.zip"
    else
        fail "Unauthorized Request. Check your username and password"
    fi
fi
