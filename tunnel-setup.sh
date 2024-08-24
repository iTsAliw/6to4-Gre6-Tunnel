#!/bin/bash

# رنگ‌ها
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
PINK='\033[1;35m'
NC='\033[0m' # بدون رنگ

# مسیر فایل لاگ
LOG_FILE="/var/log/tunnel_status.log"
UPDATE_LOG="/var/log/update_status.log"

# گرفتن IP و لوکیشن
SERVER_IP=$(curl -s ifconfig.me)
SERVER_LOCATION=$(curl -s ipinfo.io/${SERVER_IP}/city)

# Server update and upgrade
if [ ! -f "$UPDATE_LOG" ];then
    echo -e "${GREEN}Server update and upgrade...${NC}" | tee -a $LOG_FILE
    sudo apt-get update && sudo apt-get upgrade -y
    touch $UPDATE_LOG
fi

# Function to set 6to4 tunnel in Iran server
setup_iran() {
    IPv4_IRAN=$(hostname -I | awk '{print $1}')
    read -p "$(echo -e ${YELLOW}"IPV4 Kharej ra vared konid (IPv4-KHAREJ): "${NC})" IPv4_KHAREJ
    IPv6_IRAN="fde8:b030:25cf::de0"
    IPv6_KHAREJ="fde8:b030:25cf::de02"
    GRE6_LOCAL_IP="172.20.20.1"
    GRE6_REMOTE_IP="172.20.20.2"

    echo -e "${BLUE}Set the 6to4 tunnel on the Iran server${NC}" | tee -a $LOG_FILE
    sudo ip tunnel add 6to4_To_KH mode sit remote $IPv4_KHAREJ local $IPv4_IRAN ttl 255
    sudo ip link set 6to4_To_KH mtu 1480
    sudo ip addr add $IPv6_IRAN/64 dev 6to4_To_KH
    sudo ip link set 6to4_To_KH up

    echo -e "${BLUE}Set the GRE6 tunnel on the Iran server${NC}" | tee -a $LOG_FILE
    sudo ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote $IPv6_KHAREJ local $IPv6_IRAN ttl 255
    sudo ip addr add $GRE6_LOCAL_IP/30 dev GRE6Tun_To_KH
    sudo ip link set GRE6Tun_To_KH mtu 1436
    sudo ip link set GRE6Tun_To_KH up

    echo -e "${BLUE}Forwarding traffic with IP forward on Iran server${NC}" | tee -a $LOG_FILE
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination $GRE6_LOCAL_IP
    sudo iptables -t nat -A PREROUTING -j DNAT --to-destination $GRE6_REMOTE_IP
    sudo iptables -t nat -A POSTROUTING -j MASQUERADE

    echo -e "${BLUE}Configuration of tunnels and traffic forwarding was done successfully.${NC}" | tee -a $LOG_FILE
    show_menu
}

# Function to set up 6to4 tunnel in Kharej server
setup_kharej() {
    IPv4_KHAREJ=$(hostname -I | awk '{print $1}')
    read -p "$(echo -e ${YELLOW}"IPV4 Iran ra vared konid (IPv4-IRAN): "${NC})" IPv4_IRAN
    IPv6_IRAN="fde8:b030:25cf::de01"
    IPv6_KHAREJ="fde8:b030:25cf::de02"
    GRE6_LOCAL_IP="172.20.20.2"
    GRE6_REMOTE_IP="172.20.20.1"

    echo -e "${PURPLE}Set up 6to4 tunnel on Kharej server${NC}" | tee -a $LOG_FILE
    sudo ip tunnel add 6to4_To_IR mode sit remote $IPv4_IRAN local $IPv4_KHAREJ ttl 255
    sudo ip link set 6to4_To_IR mtu 1480
    sudo ip addr add $IPv6_KHAREJ/64 dev 6to4_To_IR
    sudo ip link set 6to4_To_IR up

    echo -e "${PURPLE}Set the GRE6 tunnel on the Kharej server${NC}" | tee -a $LOG_FILE
    sudo ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote $IPv6_IRAN local $IPv6_KHAREJ ttl 255
    sudo ip addr add $GRE6_LOCAL_IP/30 dev GRE6Tun_To_IR
    sudo ip link set GRE6Tun_To_IR mtu 1436
    sudo ip link set GRE6Tun_To_IR up

    echo -e "${PURPLE}Configuration of tunnels and traffic forwarding was done successfully.${NC}" | tee -a $LOG_FILE
    show_menu
}

# Function to check tunnel status
check_status() {
    GRE6_LOCAL_IP1="172.20.20.2"
    GRE6_LOCAL_IP2="172.20.20.1"

    echo -e "${CYAN}Checking tunnel status...${NC}" | tee -a $LOG_FILE
    TUNNEL_STATUS="Offline"

    if ping -c 4 $GRE6_LOCAL_IP1 > /dev/null && ping -c 4 $GRE6_LOCAL_IP2 > /dev/null; then
        TUNNEL_STATUS="${GREEN}Online${NC}"
    else
        TUNNEL_STATUS="${RED}Offline${NC}"
    fi

    echo -e "${CYAN}
Status
 '-'══════════════════════════
╭───────────────────────────────────────╮
Tunnel Status: ${TUNNEL_STATUS}
╰───────────────────────────────────────╯
${NC}" | tee -a $LOG_FILE
    echo -e "${YELLOW}Press any key to return to the main menu...${NC}"
    read -n 1 -s
    show_menu
}

# Function to show menu
show_menu() {
    clear
    echo -e "${WHITE}*Your IP Address: ${CYAN}${SERVER_IP} ${GREEN}${SERVER_LOCATION}${NC}"
    echo -e "${WHITE}https://github.com/iTsAliw${NC}"
    echo -e "${WHITE}thanks to Daniel${NC}"
    echo -e "${WHITE}
 ██████╗████████╗ ██████╗ ██╗  ██╗    ████████╗██╗   ██╗███╗   ██╗███╗   ██╗███████╗██╗                   ██╗██████╗ ██╗   ██╗ ██████╗     ██╗      ██████╗  ██████╗ █████╗ ██╗     
██╔════╝╚══██╔══╝██╔═══██╗██║  ██║    ╚══██╔══╝██║   ██║████╗  ██║████╗  ██║██╔════╝██║                   ██║██╔══██╗██║   ██║██╔════╝     ██║     ██╔═══██╗██╔════╝██╔══██╗██║     
███████╗   ██║   ██║   ██║███████║       ██║   ██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██║         █████╗    ██║██████╔╝██║   ██║███████╗     ██║     ██║   ██║██║     ███████║██║     
██╔═══██╗  ██║   ██║   ██║╚════██║       ██║   ██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██║         ╚════╝    ██║██╔═══╝ ╚██╗ ██╔╝██╔═══██╗    ██║     ██║   ██║██║     ██╔══██║██║     
╚██████╔╝  ██║   ╚██████╔╝     ██║       ██║   ╚██████╔╝██║ ╚████║██║ ╚████║███████╗███████╗              ██║██║      ╚████╔╝ ╚██████╔╝    ███████╗╚██████╔╝╚██████╗██║  ██║███████╗
 ╚═════╝   ╚═╝    ╚═════╝      ╚═╝       ╚═╝    ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚══════╝              ╚═╝╚═╝       ╚═══╝   ╚═════╝     ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝
    ${NC}"
    
    echo -e "${WHITE}==============================================================${NC}"
    echo -e "${PINK}                         Main Menu                            ${NC}"
    echo -e "${WHITE}==============================================================${NC}"
    echo -e "${YELLOW}Server Khod Ra Entekhab konid:${NC}"
    echo -e "${BLUE}1- Iran-Server${NC}"
    echo -e "${PURPLE}2- Kharej-Server${NC}"
    echo -e "${CYAN}3- Status${NC}"
    echo -e "${RED}4- Exit${NC}"
    read -p "$(echo -e ${YELLOW}"Your choice: "${NC})" choice

    case $choice in
        1)
            setup_iran
            ;;
        2)
            setup_kharej
            ;;
        3)
            check_status
            ;;
        4)
            exit 0
            ;;
        *)
            echo -e "${RED}Your choice is invalid${NC}"
            show_menu
            ;;
    esac
}

# Display menu
show_menu

# ساخته شده توسط iTsAliw
