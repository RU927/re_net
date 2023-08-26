#!/usr/bin/bash
###run this script with sudo -E -s ./retest4.sh
# net_dir=/etc/netplan
net_dir=$(pwd)
# net_file="$net_dir/01-$point-dhcp4-$dhcp4.yaml"
net_file="$net_dir"/01-config.yaml
this_dir_path="$(dirname "$(realpath "$0")")"
this_config="$(readlink -f "$0")"
keys_file="$keysdir/netkeys.sh"
vars_file="$this_dir_path/set_vars.sh"

# black='\u001b[30;1m'
red='\u001b[31;1m'
green='\u001b[32;1m'
yellow='\u001b[33;1m'
blue='\u001b[34;1m'
magenta='\u001b[35;1m'
# cyan='\u001b[36;1m'
# white='\u001b[37;1m'
# background_black='\u001b[40;1m'
# background_red='\u001b[41;1m'
# background_green='\u001b[42;1m'
# background_Yellow='\u001b[43;1m'
# background_blue='\u001b[44;1m'
# background_magenta='\u001b[45;1m'
# background_cyan='\u001b[46;1m'
# background_white='\u001b[47;1m'

# bold='\u001b[1m'
# underline='\u001b[4m'
reversed='\u001b[7m'
rc='\u001b[0m'

command source "$this_dir_path"/bin/check_adapters.sh

if [ -f "$keys_file" ]; then
	command source "$keys_file"
	echo -e "${yellow} You have a ${#points[@]} wi-fi keys ${rc}"
else
	keysdir="$HOME/.keysdir"
	echo "${yellow} keys file not found, creating him in $keysdir ${rc}"
	mkdir -p "$keysdir"
	echo -e '#!/bin/bash \ndeclare -A points' >"$keys_file"
	command source "$keys_file"
	echo -e "${yellow} You have a ${#points[@]} wi-fi keys ${rc}"
fi

key_point=("${!points[@]}")
key_pass_point=("${points[@]}")
# echo -e "${key_point[@]}"
# echo -e "${key_pass_point[@]}"
renderer_list=("NetworkManager" "networkd")
interface_list=("ethernets" "wifis")
adapter_list=("$radio_adapter" "$lan_adapter")
dhcp4_list=("true" "no")
var_router_list=("1" "0" "10")
var_router2_list=("192.168" "172.20")
local_ip_list=("27" "9" "10" "12")
common_list=("no" "wifis" "ethernets" "all")

renderer=${renderer_list[0]}
interface=${interface_list[1]}
adapter=${adapter_list[0]}
dhcp4=${dhcp4_list[0]}
var_router=${var_router_list[0]}
var_router2=${var_router2_list[0]}
point=${key_point[0]}
pass_point=${key_pass_point[0]}
local_ip=${local_ip_list[0]}
common=${common_list[0]}

if [ -f "$vars_file" ]; then
	command source "$vars_file"
fi

vars_memory=()
for a in "$@"; do
	vars_memory=("${vars_memory[@]}" "$a")
	eval "$a"
done

if [ "$interface" = wifis ]; then
	adapter=$radio_adapter
elif [ "$interface" = ethernets ]; then
	adapter=$lan_adapter
fi

dhcp4_addresses=["$var_router2"."$var_router"."$local_ip"/24]
routes_via="$var_router2"."$var_router".1
nameserv_addr=[8.8.8.8,8.8.4.4]
# nameserv_addr=[192.168."${var_router}".1,8.8.8.8]

echo_f() {
	echo "network:"
	echo "  version: 2"
	echo "  renderer: $renderer"
}
interface() {
	echo "  $interface:"
}
adapter() {
	echo "    $adapter:"
}
access-points() {
	echo "      access-points:"
}
wifi_point() {
	echo "        $point:"
	echo "          password: $pass_point"
}
dhcp_status() {
	echo "      dhcp4: $dhcp4"
}
dhcp4_stat() {
	echo "      addresses: $dhcp4_addresses"
	echo "      routes:"
	echo "      - to: default"
	echo "        via: $routes_via"
	echo "      nameservers:"
	echo "        addresses: $nameserv_addr"
}

if [ "$common" = "no" ]; then

	if [ "$interface" = wifis ]; then
		if [ "$dhcp4" = true ]; then
			up() {
				echo_f
				interface
				adapter
				access-points
				wifi_point
				dhcp_status
			}
		elif [ "$dhcp4" = no ]; then
			up() {
				echo_f
				interface
				adapter
				access-points
				wifi_point
				dhcp_status
				dhcp4_stat
			}
		fi
	elif [ "$interface" = ethernets ]; then
		up() {
			echo_f
			interface
			adapter
			dhcp4_stat
		}
	fi

elif [ "$common" != "no" ]; then

	if [ "$common" = "wifis" ]; then
		up() {
			echo_f
			interface
			adapter
			access-points
			for p in "${pts[@]}"; do
				for a in "${key_point[@]}"; do
					[[ "$p" = "$a" ]] && break
				done
				point="$a"
				pass_point="${points[$a]}"
				wifi_point
			done
			dhcp_status
		}

	elif [ "$common" = "all" ]; then
		up() {
			echo_f
			for i in "${interface_list[@]}"; do
				interface=$i

				if [ "$interface" = ethernets ]; then
					adapter=$lan_adapter
					interface
					adapter
					dhcp4_stat
				elif [ "$interface" = wifis ]; then
					adapter=$radio_adapter
					interface
					adapter
					access-points
					dhcp_status
					if [ "${#pts[@]}" != 0 ]; then
						for p in "${pts[@]}"; do
							for a in "${key_point[@]}"; do
								[[ "$p" = "$a" ]] && break
							done
							point="$a"
							pass_point="${points[$a]}"
							wifi_point
						done
					else
						wifi_point
					fi
				fi
			done
		}
		# elif [ "$common" = "ethernets"]; then
	fi
fi

function whatsmyip() {
	echo -n "Internal IP: "
	ifconfig "$radio_adapter" | grep "inet " | awk -F: '{print $1}' | awk '{print $2}'
	echo -n "External IP: "
	dig @resolver4.opendns.com myip.opendns.com +short
}

# Menu TUI
echo -e "${magenta}${reversed} setting up netplan ${rc}"
echo -e "$(up)"
echo -e "${blue} (y) confirm ${rc}"
echo -e "${blue} (a) any points ${rc}"
echo -e "${blue} (d) change dhcp ${rc}"
echo -e "${blue} (i) change interface ${rc}"
echo -e "${blue} (p) change local ip ${rc}"
echo -e "${blue} (v) change router specific 0/1/10 ${rc}"
echo -e "${blue} (v2) change router specific 192.168/172.210 ${rc}"
echo -e "${blue} (c) common change ${rc}"
echo -e "${red} (x) Anything else to exit ${rc}"
echo -en "${green} ==> ${rc}"

read -r option
case $option in
"y")
	# rm -rf "$net_dir"/01-*.yaml
	# if [ ! -f "$net_file" ]; then
	# 	touch "$net_file"
	# 	chmod 600 "$net_file"
	# fi
	up >"$net_file"
	# netplan apply
	# sleep 1
	# whatsmyip
	echo -e "${blue}saved variables at file ?${rc}"
	echo -e "${blue}(y) - save at $vars_file ${rc}"
	echo -e "${blue}(n) - no ${rc}"

	read -r save
	case $save in
	"y")
		echo -e '#!/bin/bash' >"$vars_file"
		for v in "${vars_memory[@]}"; do
			echo -e "$v" >>"$vars_file"
		done
		;;
	"n")
		exit
		;;
	esac
	;;

"a")
	echo -e "${magenta} setting up point ${rc}"
	count=0
	for p in "${key_point[@]}"; do
		count="$(("$count" + 1))"
		echo -e "${blue} ($count) - $p ${rc} "
	done
	echo -e "${blue} (s) - scan wi-fi points ${rc} "
	echo -e "${red} (x) - exit ${rc}"
	echo -en "${green} ==> ${rc}"

	read -r op
	case $op in
	[0-9])
		p_ind="$(("$op" - 1))"
		vars_memory=("${vars_memory[@]}" "point=${key_point[$p_ind]}" "pass_point=${key_pass_point[$p_ind]}")
		"$this_config" "${vars_memory[@]}"
		;;

	"s")
		echo -e "${magenta} scan wi-fi point ${rc}"
		arr_pnt=()
		cnt=0
		list_pnts=$("$this_dir_path"/bin/wifi_list.sh)
		for ps in $list_pnts; do
			arr_pnt+=("$ps")
			cnt="$(("$cnt" + 1))"
			echo -e "${blue} ($cnt) - $ps ${rc} "
		done
		echo -e "${red} (x) exit ${rc}"
		echo -en "${green} ==> ${rc}"

		read -r pnt
		case $pnt in
		*[0-9]*)
			num=$(("$pnt" - 1))
			pname=${arr_pnt[$num]}
			echo -n "enter the password for $pname: "
			read -r pn_pass
			echo -e "points[$pname]=$pn_pass" >>"$keysdir/netkeys.sh"

			key_point=("${key_point[@]}" "$pname")
			key_pass_point=("${key_pass_point[@]}" "$pn_pass")

			corr_num=$(("${#key_point[@]}" - 1))

			vars_memory=("${vars_memory[@]}" "point=${key_point[$corr_num]}" "pass_point=${key_pass_point[$corr_num]}")
			"$this_config" "${vars_memory[@]}"
			;;
		esac

		echo -e "${red} (x) exit ${rc}"
		echo -en "${green} ==> ${rc}"
		;;

	# '' | *[!0-9]*)
	# 	echo "${red} bad option"
	# 	"$this_config"
	# 	;;
	esac
	;;

"d")
	if [ "$dhcp4" = "true" ]; then
		vars_memory=("${vars_memory[@]}" "dhcp4=no")
	elif [ "$dhcp4" = "no" ]; then
		vars_memory=("${vars_memory[@]}" "dhcp4=true")
	fi
	"$this_config" "${vars_memory[@]}"
	;;

"i")
	if [ "$interface" = "wifis" ]; then
		vars_memory=("${vars_memory[@]}" "interface=ethernets")
	elif [ "$interface" = "ethernets" ]; then
		vars_memory=("${vars_memory[@]}" "interface=wifis")
	fi
	"$this_config" "${vars_memory[@]}"
	;;

"p")
	sum="${#local_ip_list[@]}"
	sum_ind=$(("$sum" - 1))
	for i in "${!local_ip_list[@]}"; do
		[[ "${local_ip_list[$i]}" = "$local_ip" ]] && break
	done
	ip_ind="$i"
	if [[ "$ip_ind" -lt "$sum_ind" ]]; then
		ip_ind=$(("$ip_ind" + 1))
		vars_memory=("${vars_memory[@]}" "local_ip=${local_ip_list[$ip_ind]}")
	else
		ip_ind=0
		vars_memory=("${vars_memory[@]}" "local_ip=${local_ip_list[$ip_ind]}")
	fi
	"$this_config" "${vars_memory[@]}"
	;;

"v")
	sum="${#var_router_list[@]}"
	sum_ind=$(("$sum" - 1))
	for i in "${!var_router_list[@]}"; do
		[[ "${var_router_list[$i]}" = "$var_router" ]] && break
	done
	var_ind="$i"
	if [[ "$var_ind" -lt "$sum_ind" ]]; then
		var_ind=$(("$var_ind" + 1))
		vars_memory=("${vars_memory[@]}" "var_router=${var_router_list[$var_ind]}")
	else
		var_ind=0
		vars_memory=("${vars_memory[@]}" "var_router=${var_router_list[$var_ind]}")
	fi
	"$this_config" "${vars_memory[@]}"
	;;

"v2")
	sum="${#var_router2_list[@]}"
	sum_ind=$(("$sum" - 1))
	for i in "${!var_router2_list[@]}"; do
		[[ "${var_router2_list[$i]}" = "$var_router2" ]] && break
	done
	var2_ind="$i"
	if [[ "$var2_ind" -lt "$sum_ind" ]]; then
		var2_ind=$(("$var2_ind" + 1))
		vars_memory=("${vars_memory[@]}" "var_router2=${var_router2_list[$var2_ind]}")
	else
		var2_ind=0
		vars_memory=("${vars_memory[@]}" "var_router2=${var_router2_list[$var2_ind]}")
	fi
	"$this_config" "${vars_memory[@]}"
	;;

"c")
	# sum="${#common_list[@]}"
	# sum_ind=$(("$sum" - 1))

	# for i in "${!common_list[@]}"; do
	# 	[[ "${common_list[$i]}" = "$common" ]] && break
	# done
	# common_ind="$i"

	echo -e "${magenta} setting up common ${rc}"
	count=0
	for p in "${common_list[@]}"; do
		count="$(("$count" + 1))"
		echo -e "${blue} ($count) - $p ${rc} "
	done
	echo -e "${red} (x) - exit ${rc}"
	echo -en "${green} ==> ${rc}"

	read -r op
	case $op in

	"$op")
		c_ind="$(("$op" - 1))"
		common="${common_list[$c_ind]}"
		if [ "$common" = "wifis" ]; then
			count=0
			for i in "${!points[@]}"; do
				count="$(("$count" + 1))"
				echo -e "${blue} ($count) - add $i"
			done
			echo -en "${green} ==> ${rc}"

			read -r c
			case $c in
			"$c")
				p_ind="$(("$c" - 1))"
				p="${key_point[$p_ind]}"
				pts=("${pts[@]}" "$p")
				# exec
				;;
			esac
		fi
		;;
	esac

	# if [[ "$common_ind" -lt "$sum_ind" ]]; then
	# 	common_ind=$(("$common_ind" + 1))
	# else
	# 	common_ind=0
	# fi
	vars_memory=("${vars_memory[@]}" "common=$common" "pts=(${pts[*]})")

	"$this_config" "${vars_memory[@]}"

	;;

x)
	echo -e "${green} invalid option entered, bye! ${rc}"
	exit 0
	;;
esac

# idx=0
# for p in "${local_ip_list[@]}"; do
# 	vars_memory=("${vars_memory[@]}" "local_ip=${local_ip_list[idx]}")
# 	idx="$(("$idx" + 1))"
# done

# exit 0

#run this script with sudo -E -s ./netplan.sh.sh
