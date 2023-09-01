#!/bin/bash
if [ -z "$1" ] ; then
  echo "Usage: $0 CLIENT_ID"
  exit 1
fi
docker-compose exec dockovpn ./rmclient.sh $1
