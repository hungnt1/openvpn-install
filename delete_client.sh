function revokeClient() {
        CLIENT=$1
        cd /etc/openvpn/easy-rsa/ || return
        ./easyrsa --batch revoke "$CLIENT"
        EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
        rm -f /etc/openvpn/crl.pem
        cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
        chmod 644 /etc/openvpn/crl.pem
        find /home/ -maxdepth 2 -name "$CLIENT.ovpn" -delete
        rm -f "$HOME/$CLIENT.ovpn"
        sed -i "/^$CLIENT,.*/d" /etc/openvpn/ipp.txt
        echo "Kick client if connected"
        
        echo "kill $CLIENT" >/dev/tcp/localhost/7505

        echo ""
        echo "Certificate for client $CLIENT revoked."
}

revokeClient $1


