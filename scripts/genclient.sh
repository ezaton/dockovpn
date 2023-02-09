#!/bin/bash

source ./functions.sh


CONTENT_TYPE=application/text
FILE_NAME=client.ovpn


while getopts 'vhzop:u:' flag; do 
    case "${flag}" in
        h)  print_usage
            ;;
        z)  FLAGS="${FLAGS}z"
            ;;
        p)  FLAGS="${FLAGS}p"
            pass=${OPTARG}
            ;;
        o)  FLAGS="${FLAGS}o"
            ;;
        u)  name=${OPTARG}
            ;;
        v)  version
            exit 0
            ;;
        *)  print_usage
            ;;
    esac
done

CLIENT_PATH="$(createConfig ${name})"
if [ $? -ne 0 ]; then
    [ -n "${name}" ] && CLIENT_PATH=${name}
    echo "$(datef) Cannot create client ${CLIENT_PATH}" && exit 1
fi
FILE_PATH="$CLIENT_PATH/$FILE_NAME"
# Possible permutations:
# Switch statement
if [ -n "${FLAGS}" ]; then
    case $FLAGS in
        z)
            zipFiles "$CLIENT_PATH"

            CONTENT_TYPE=application/zip
            FILE_NAME=client.zip
            FILE_PATH="$CLIENT_PATH/$FILE_NAME"
            ;;
        zp)
            # (()) engaes arthimetic context
            if [ -z "$pass" ]
            then
                echo "$(datef) Not enough arguments" && exit 1
            else
                zipFilesWithPassword "$CLIENT_PATH" "$pass"

                CONTENT_TYPE=application/zip
                FILE_NAME=client.zip
                FILE_PATH="$CLIENT_PATH/$FILE_NAME"
            fi
            ;;
        o)
                cat "$FILE_PATH"
                exit 0
            ;;
        oz)
            zipFiles "$CLIENT_PATH" -q

            FILE_NAME=client.zip
            FILE_PATH="$CLIENT_PATH/$FILE_NAME"
            cat "$FILE_PATH"
            exit 0
            ;;
        ozp)
            if [ -z "$pass" ]
            then
                echo "$(datef) Not enough arguments" && exit 1
            else
                zipFilesWithPassword "$CLIENT_PATH" "$2" -q

                FILE_NAME=client.zip
                FILE_PATH="$CLIENT_PATH/$FILE_NAME"
                cat "$FILE_PATH"
                exit 0
            fi
            ;;
        *)  
            echo "$(datef) Unknown parameters $FLAGS"
            ;;

    esac
fi

echo "$(datef) $FILE_PATH file has been generated"

echo "$(datef) Config server started, download your $FILE_NAME config at http://$HOST_ADDR:$HOST_CONF_PORT/"
echo "$(datef) NOTE: After you download your client config, http server will be shut down!"

{ echo -ne "HTTP/1.1 200 OK\r\nContent-Length: $(wc -c <$FILE_PATH)\r\nContent-Type: $CONTENT_TYPE\r\nContent-Disposition: attachment; fileName=\"$FILE_NAME\"\r\nAccept-Ranges: bytes\r\n\r\n"; cat "$FILE_PATH"; } | nc -w0 -l 8080

echo "$(datef) Config http server has been shut down"