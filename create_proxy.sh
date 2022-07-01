#/bin/bash
read -p "Fresh Installation? y/n: " answer
if [ "$answer" != "${answer#[Yy]}" ] ;then 
    echo Yes
    
    echo "[1] - Installing updates"
    apt update && sudo apt upgrade

    echo "[2] - Setting up a proxy server"
    yes | sudo apt install dante-server
    yes | sudo apt install curl

else
echo No

read -p "Press 'Enter' to exit"
exit

echo "[3] - Getting a network profile"
read -p "adress to ping?: " pingad
read -p "$pingad - is this correct? y/n" answer2
if [ "$answer2" != "${answer2#[Yy]}" ] ;then 
ext_interface () {
    for interface in /sys/class/net/*
    do
        [[ "${interface##*/}" != 'lo' ]] && \
            ping -c1 -W2 -I "${interface##*/}" ${pingad} >/dev/null 2>&1 && \
                printf '%s' "${interface##*/}" && return 0
    done
}

else
exit
fi

echo "[4] - Adding a config server"
echo "logoutput: stderr" > /etc/danted.conf
echo"Define portrange"
read -p "First in port range: " port1
read -p "Last in port range: " port2
for ((i = ${port1}; i <= ${port2}; i++))
    do
        echo "internal: $(ext_interface) port = $i" >> /etc/danted.conf
        echo "[5] - Adding rules to the server"
        iptables -A INPUT -p tcp --dport "$i" -j ACCEPT
        ufw allow "$i"/tcp
    done
echo "external: $(ext_interface)" >> /etc/danted.conf
echo "socksmethod: username" >> /etc/danted.conf
echo "user.privileged: root" >> /etc/danted.conf
echo "user.unprivileged: nobody" >> /etc/danted.conf
echo "user.libwrap: nobody" >> /etc/danted.conf
echo " client pass {" >> /etc/danted.conf
echo "        from: 0.0.0.0/0 to: 0.0.0.0/0" >> /etc/danted.conf
echo "        log: connect error" >> /etc/danted.conf
echo "}" >> /etc/danted.conf
echo "socks pass {" >> /etc/danted.conf
echo "        from: 0.0.0.0/0 to: 0.0.0.0/0" >> /etc/danted.conf
echo "        log: connect error" >> /etc/danted.conf
echo "}" >> /etc/danted.conf

echo "[6] - Create a user, @ not allowed!"
read -p "Enter user name: " user
read -p "Enter user password : " pass
useradd -s /bin/false ${user}
echo "$user:$pass" | chpasswd

echo "[7] - Restarting the server service"
systemctl restart danted
systemctl enable danted

echo "[8] - Checking proxy availability"
for ((i = ${port1}; i <= ${port2}; i++))
    do
      curl --socks5 ${user}:${pass}@$(ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | head -n 1 | awk '/inet/ {print $2}' | cut -d'/' -f1):${i} ident.me; echo
    done

echo "[9] - For manual testing"
for ((i = ${port1}; i <= ${port2}; i++))
    do
      echo "curl --socks5 ${user}:${pass}@$(ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | head -n 1 | awk '/inet/ {print $2}' | cut -d'/' -f1):${i} ident.me; echo"
    done

echo "[!] Your proxy list"
for ((i = ${port1}; i <= ${port2}; i++))
    do
      echo "${user}:${pass}@$(ip addr show $(ip route | awk '/default/ { print $5 }') | grep "inet" | head -n 1 | awk '/inet/ {print $2}' | cut -d'/' -f1):${i}"
    done
fi
echo "[10] - DONE!!!"
