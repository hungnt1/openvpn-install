function newClient() {
	echo ""
	echo "Tell me a name for the client."
	echo "The name must consist of alphanumeric character. It may also include an underscore or a dash."

        CLIENT=$1
        PASS=1
        echo "client $CLIENT"
	echo ""


	CLIENTEXISTS=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c -E "/CN=$CLIENT\$")
	if [[ $CLIENTEXISTS == '1' ]]; then
		echo ""
		echo "The specified client CN was already found in easy-rsa, please choose another name."
		exit
	else
		cd /etc/openvpn/easy-rsa/ || return
		case $PASS in
		1)
			./easyrsa build-client-full "$CLIENT" nopass
			;;
		2)
			echo "âš ï¸ You will be asked for the client password below âš ï¸"
			./easyrsa build-client-full "$CLIENT"
			;;
		esac
		echo "Client $CLIENT added."
	fi

	# Home directory of the user, where the client configuration (.ovpn) will be written
	if [ -e "/home/$CLIENT" ]; then # if $1 is a user name
		homeDir="/home/$CLIENT"
	elif [ "${SUDO_USER}" ]; then # if not, use SUDO_USER
		homeDir="/home/${SUDO_USER}"
	else # if not SUDO_USER, use /root
		homeDir="/root"
	fi

	# Determine if we use tls-auth or tls-crypt
	if grep -qs "^tls-crypt" /etc/openvpn/server.conf; then
		TLS_SIG="1"
	elif grep -qs "^tls-auth" /etc/openvpn/server.conf; then
		TLS_SIG="2"
	fi

	# Generates the custom client.ovpn
	cp /etc/openvpn/client-template.txt "/var/www/iedge.iview.vn/public/$CLIENT.ovpn"
	{
		echo "<ca>"
		cat "/etc/openvpn/easy-rsa/pki/ca.crt"
		echo "</ca>"

		echo "<cert>"
		awk '/BEGIN/,/END/' "/etc/openvpn/easy-rsa/pki/issued/$CLIENT.crt"
		echo "</cert>"

		echo "<key>"
		cat "/etc/openvpn/easy-rsa/pki/private/$CLIENT.key"
		echo "</key>"

		case $TLS_SIG in
		1)
			echo "<tls-crypt>"
			cat /etc/openvpn/tls-crypt.key
			echo "</tls-crypt>"
			;;
		2)
			echo "key-direction 1"
			echo "<tls-auth>"
			cat /etc/openvpn/tls-auth.key
			echo "</tls-auth>"
			;;
		esac
	} >>"/var/www/iedge.iview.vn/public/$CLIENT.ovpn"

	echo ""
	echo "The configuration file has been written to /var/www/iedge.iview.vn/public/$CLIENT.ovpn."
	echo "Download the .ovpn file and import it in your OpenVPN client."

	exit 0
}

newClient $1
