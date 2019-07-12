#!/usr/bin/env bash
# -v "$(pwd)"/script/runtime:/opt/teleport/runtime
docker run --cap-add=NET_ADMIN \
-it -p 1194:1194/udp -p 8080:8080/tcp \
-e HOST_ADDR=localhost alekslitvinenk/openvpn "$@"