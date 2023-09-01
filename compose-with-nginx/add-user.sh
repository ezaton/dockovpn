#!/bin/bash
echo "Without arguments, certificate name will be random"
echo "To set a name, use '-u name' in the command line"
echo "Press Enter to continue or Ctrl+C to abort"
read tempvar
docker-compose exec dockovpn ./genclient.sh $@
