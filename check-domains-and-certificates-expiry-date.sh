#!/bin/bash

# domains to check
DOMAINS=( google.com youtube.com github.com )

###### do not modify below ######
# Colors for msg_box
DGREEN=$'\e[32m'
GRAY=$'\e[37m'
DGRAY=$'\e[90m'
GREEN=$'\e[92m'
YELLOW=$'\e[93m'
NORMAL=$'\e[0m'

# messages
DONE="${DGREEN}[${GREEN} DONE ${DGREEN}]"

error_quit()
{
	message_error $err
	exit 1
}

msg_box() {
    local term_width=80
    local str=("$@") msg_width
    printf '\n'
    COLOR_FRAME=${DGREEN}
    COLOR_TEXT=${GREEN}

    for line in "${str[@]}"; do
        ((msg_width<${#line})) && { msg_width="${#line}"; }

        if [ $msg_width -gt $term_width ]; then
            error_quit "\$msg_width exceeds \$term_width.\n"
        fi

        x=$(($term_width - $msg_width))
        pad=$(($x / 2))
    done

    printf '%s┌' "${COLOR_FRAME}" && printf '%.0s─' {0..79} && printf '┐\n' && printf '│%79s │\n'

    for line in "${str[@]}"; do
        rpad=$((80 - $pad - $msg_width))
        printf "│%$pad.${pad}s" && printf '%s%*s' "$COLOR_TEXT" "-$msg_width" "$line" "${COLOR_FRAME}" && printf "%$rpad.${rpad}s│\n"
    done

    printf '│%79s │\n' && printf  '└' && printf '%.0s─' {0..79}  && printf '┘\n%s' ${NORMAL} ${RESET}
}

menu(){
	clear
	msg_box "Domain and Certificate check v1.0.0 by GMBroker"
	echo -e "$DGREEN"
	echo " [Commands]"
	echo -e "  Press ${DGRAY}[${GRAY}1${DGRAY}]${DGREEN} check domains expiration date"
	echo -e "  Press ${DGRAY}[${GRAY}2${DGRAY}]${DGREEN} check certificate expiration date"
	echo -e "  Press ${DGRAY}[${GRAY}q${DGRAY}]${DGREEN} to exit"
	echo -e "\n"
	echo -e "${NORMAL}======================================================================="
	echo -e "Enter your selection: \c"
}

check_certificates(){
for CERT in "${DOMAINS[@]}";
do
        now_epoch=$( date +%s )

        dig +noall +answer $CERT | while read _ _ _ _ ip;
        do
		echo -ne "${DONE} Checking certificate on domain ${YELLOW}${CERT} "
                echo -ne "${DGREEN}[${NORMAL}$ip${DGREEN}] - "
                expiry_date=$( echo | openssl s_client -showcerts -servername $CERT -connect $ip:443 2>/dev/null | openssl x509 -inform pem -noout -enddate | cut -d "=" -f 2 )
                echo -ne "${NORMAL} $expiry_date";
                expiry_epoch=$( date -d "$expiry_date" +%s )
                expiry_days="$(( ($expiry_epoch - $now_epoch) / (3600 * 24) ))"
                echo -e "   ${DGREEN}- ${YELLOW}$expiry_days days left${NORMAL}"
        done
done
}

check_domains(){
for DOMAIN in "${DOMAINS[@]}";
do
	now_epoch=$( date +%s )

        dig +noall +answer $DOMAIN | while read _ _ _ _ ip;
        do
		expiry_date=$( whois $DOMAIN | grep "Expiry" | cut -d ':' -f2 | cut -d 'T' -f-1 )
		if [ ! -z "$expiry_date" ]; then
                echo -ne "${DONE} Checking domain ${YELLOW}${DOMAIN} "
                echo -ne "${DGREEN}[${NORMAL}$ip${DGREEN}] - "
#		expiry_date=$( whois $DOMAIN | grep "Expiry" | cut -d ':' -f2 | cut -d 'T' -f-1 )
                echo -ne "${NORMAL} $expiry_date";
                expiry_epoch=$( date -d "$expiry_date" +%s )
                expiry_days="$(( ($expiry_epoch - $now_epoch) / (3600 * 24) ))"
                echo -e "   ${DGREEN}- ${YELLOW}$expiry_days days left${NORMAL}"
		fi
        done

done
}


# force user to exit by q
trap '' 2
while true
do
  menu
  read answer
  case "$answer" in
  1) check_domains ;;
  2) check_certificates ;;
  q) clear
  exit ;;
esac
echo -e "Press ENTER to continue \c"
read input
done
