#!/usr/bin/bash

RC='\e[0m'
# RV='\u001b[7m'
RED='\e[31m'
# YELLOW='\e[33m'
GREEN='\e[32m'
GREEN2='[32;1m'
WHITE='[37;1m'
BLUE='[34;1m'

if [ -f "$KEYSDIR/keysnet" ]; then
	command source "$KEYSDIR/keysnet"
else
	echo "keys file not found"
	exit 1
fi

if [ "$HOSTNAME" = vaio ]; then
	radio_adapter=wlp7s0
	# lan_adapter=enp2s0
	ip=9
elif [ "$HOSTNAME" = pcRU ]; then
	radio_adapter=wlx60e32716669c
	lan_adapter=enp2s0
	ip=27
fi

renderer_n=networkd
renderer_N=NetworkManager

interface=("wifis" "ethernets")
adapter=("$radio_adapter" "$lan_adapter")

dhcp4_ref=("true" "no")
var_routes=("1" "0")

INTERFACE="${interface[0]}"
ADAPTER="${adapter[0]}"
POINT=$wan_point3
PASS_POINT=$wan_pass_point3
DHCP4_REF="${dhcp4_ref[0]}"
VAR_ROUTES="${var_routes[0]}"

# for i in "$@"; do
# 	case $i in
# 	--point=*) #wan_point{1,2,3}
# 		POINT="${i:8}"
# 		;;
# 	--pass=*) #wan_pass_point{1,2,3}
# 		PASS_POINT="${i:7}"
# 		;;
# 	esac
# done

for i in "$@"; do
	case $i in
	--point=*) #1,2,3
		eval POINT=\$wan_point"${i:8}"
		eval PASS_POINT=\$wan_pass_point"${i:8}"
		;;
	esac
done

dhcp4_addresses=[192.168."${VAR_ROUTES}".$ip/24]
routes_via=192.168."${VAR_ROUTES}".1
# nameserv_addr_def=[8.8.8.8,8.8.4.4]
nameserv_addr=[192.168."${VAR_ROUTES}".1,8.8.8.8]

echo_f() {
	echo "network:                               "
	echo "  version: 2                           "
	echo "  renderer: $renderer_N                "
	echo "  $INTERFACE:                             "
	echo "    $ADAPTER:                          "
}
wifi_dhcp() {
	echo "      access-points:                   "
	echo "        $POINT:                       "
	echo "          password: $PASS_POINT          "
	echo "      dhcp4: $DHCP4_REF                "
}
dhcp4_stat() {
	echo "      addresses: $dhcp4_addresses      "
	echo "      routes:                          "
	echo "      - to: default                    "
	echo "        via: $routes_via               "
	echo "      nameservers:                     "
	echo "        addresses: $nameserv_addr      "
}

# if [ $interface = 1 ]; then
# 	if [ $dhcp4 = 1 ]; then
up_wi-fi_dhcp_true() {
	echo_f
	wifi_dhcp
}
# elif [ $dhcp4 = 0 ]; then
up_wi-fi_dhcp_stat() {
	echo_f
	wifi_dhcp
	dhcp4_stat
}
# fi
# elif [ $interface = 2 ]; then
up_lan() {
	echo_f
	dhcp4_stat
}
# fi

# net_dir=/etc/netplan
net_dir=$(pwd)
# net_file="$net_dir/01-$POINT-dhcp4-$DHCP4_REF.yaml"
net_file="$net_dir"/01-config.yaml
# net_file="$net_dir"/01-config.yaml

# rm -rf "$net_dir"/01-*.yaml

if [ ! -f "$net_file" ]; then
	touch "$net_file"
	# chmod 600 "$net_file"
fi

# Menu TUI
echo -e "\u001b${GREEN} Setting up Dotfiles...${RC}"

echo -e " \u001b${WHITE}\u001b[4mSelect an option:${RC}"
echo -e "  \u001b${BLUE} (1) wi-fi dinamyc ip ${RC}"
echo -e "  \u001b${BLUE} (2) wi-fi static ip ${RC}"
echo -e "  \u001b${BLUE} (3) lan ${RC}"
# echo -e "  \u001b${BLUE} (4)  ${RC}"
echo -e "  \u001b${RED} (*) Anything else to exit ${RC}"

echo -en "\u001b${GREEN2} ==> ${RC}"

read -r option

case $option in

"1")
	up_wi-fi_dhcp_true >"$net_file"
	;;

"2")
	up_wi-fi_dhcp_stat >"$net_file"
	;;

"3")
	up_lan >"$net_file"
	;;

# "4")
#
# 	;;
*)
	echo -e "\u001b[31;1m Invalid option entered, Bye! ${RC}"
	exit 0
	;;
esac

# exit 0

# up >"$net_file"

# netplan apply

# function whatsmyip() {
# 	# Internal IP Lookup
# 	echo -n "Internal IP: "
# 	# ifconfig enp2s0 \
# 	ifconfig "$radio_adapter" |
# 		# grep "inet" | awk -F: '{print $2}' | awk '{print $1}'
# 		grep "inet " | awk -F: '{print $1}' | awk '{print $2}'
# 	# External IP Lookup
# 	echo -n "External IP: "
# 	# wget http://smart-ip.net/myip -O - -q
# 	dig @resolver4.opendns.com myip.opendns.com +short
# }
# # sleep 1
#
# whatsmyip

#run this script with sudo -E -s ./renet.sh
