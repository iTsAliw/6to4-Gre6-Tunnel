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

# گرفتن IP و لوکیشن
SERVER_IP=$(curl -s ifconfig.me)
SERVER_LOCATION=$(curl -s ipinfo.io/${SERVER_IP}/city)

# تنظیم تونل در سرور ایران
setup_iran() {
    IPv4_IRAN=$(hostname -I | awk '{print $1}')
    read -p "$(echo -e ${YELLOW}"IPV4 Kharej ra vared konid (IPv4-KHAREJ): "${NC})" IPv4_KHAREJ
    IPv6_IRAN="fde8:b030:25cf::de01"
    IPv6_KHAREJ="fde8:b030:25cf::de02"
    IPIP6_LOCAL_IP="172.20.20.1"
    IPIP6_REMOTE_IP="172.20.20.2"

    echo -e "${BLUE}Setting up the 6to4 tunnel on Iran server${NC}" | tee -a $LOG_FILE
    sudo ip tunnel add 6to4_To_KH mode sit remote $IPv4_KHAREJ local $IPv4_IRAN ttl 255
    sudo ip link set 6to4_To_KH mtu 1480
    sudo ip addr add $IPv6_IRAN/64 dev 6to4_To_KH
    sudo ip link set 6to4_To_KH up

    echo -e "${BLUE}Setting up the IPIP6 tunnel on Iran server${NC}" | tee -a $LOG_FILE
    sudo ip -6 tunnel add IPIP6Tun_To_KH mode ipip6 remote $IPv6_KHAREJ local $IPv6_IRAN ttl 255
    sudo ip addr add $IPIP6_LOCAL_IP/30 dev IPIP6Tun_To_KH
    sudo ip link set IPIP6Tun_To_KH mtu 1436
    sudo ip link set IPIP6Tun_To_KH up

    echo -e "${BLUE}Enabling IP forwarding and NAT on Iran server${NC}" | tee -a $LOG_FILE
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo iptables -t nat -A POSTROUTING -o IPIP6Tun_To_KH -j MASQUERADE

    echo -e "${BLUE}Tunnel setup complete!${NC}" | tee -a $LOG_FILE
    show_menu
}

# تنظیم تونل در سرور خارج
setup_kharej() {
    IPv4_KHAREJ=$(hostname -I | awk '{print $1}')
    read -p "$(echo -e ${YELLOW}"IPV4 Iran ra vared konid (IPv4-IRAN): "${NC})" IPv4_IRAN
    IPv6_IRAN="fde8:b030:25cf::de01"
    IPv6_KHAREJ="fde8:b030:25cf::de02"
    IPIP6_LOCAL_IP="172.20.20.2"
    IPIP6_REMOTE_IP="172.20.20.1"

    echo -e "${PURPLE}Setting up the 6to4 tunnel on Kharej server${NC}" | tee -a $LOG_FILE
    sudo ip tunnel add 6to4_To_IR mode sit remote $IPv4_IRAN local $IPv4_KHAREJ ttl 255
    sudo ip link set 6to4_To_IR mtu 1480
    sudo ip addr add $IPv6_KHAREJ/64 dev 6to4_To_IR
    sudo ip link set 6to4_To_IR up

    echo -e "${PURPLE}Setting up the IPIP6 tunnel on Kharej server${NC}" | tee -a $LOG_FILE
    sudo ip -6 tunnel add IPIP6Tun_To_IR mode ipip6 remote $IPv6_IRAN local $IPv6_KHAREJ ttl 255
    sudo ip addr add $IPIP6_LOCAL_IP/30 dev IPIP6Tun_To_IR
    sudo ip link set IPIP6Tun_To_IR mtu 1436
    sudo ip link set IPIP6Tun_To_IR up

    echo -e "${PURPLE}Tunnel setup complete!${NC}" | tee -a $LOG_FILE
    show_menu
}

# بررسی وضعیت تونل
check_status() {
    IPIP6_LOCAL_IP1="172.20.20.2"
    IPIP6_LOCAL_IP2="172.20.20.1"

    echo -e "${CYAN}Checking tunnel status...${NC}" | tee -a $LOG_FILE
    TUNNEL_STATUS="Offline"

    if ping -c 4 $IPIP6_LOCAL_IP1 > /dev/null && ping -c 4 $IPIP6_LOCAL_IP2 > /dev/null; then
        TUNNEL_STATUS="${GREEN}Online${NC}"
    else
        TUNNEL_STATUS="${RED}Offline${NC}"
    fi

    echo -e "${CYAN}Tunnel Status: ${TUNNEL_STATUS}${NC}" | tee -a $LOG_FILE
    echo -e "${YELLOW}Press any key to return to the main menu...${NC}"
    read -n 1 -s
    show_menu
}

# نمایش منو
show_menu() {
    clear
    echo -e "${WHITE}Your IP Address: ${CYAN}${SERVER_IP} ${GREEN}${SERVER_LOCATION}${NC}"
    echo -e "${WHITE}GitHub: https://github.com/iTsAliw${NC}"
    echo -e "${WHITE}Thanks to Daniel${NC}"
    echo -e "${WHITE}========================================${NC}"
    echo -e "${PINK}             Main Menu                 ${NC}"
    echo -e "${WHITE}========================================${NC}"
    echo -e "${YELLOW}Select your server:${NC}"
    echo -e "${BLUE}1- Iran Server${NC}"
    echo -e "${PURPLE}2- Kharej Server${NC}"
    echo -e "${CYAN}3- Check Tunnel Status${NC}"
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
            echo -e "${RED}Invalid choice!${NC}"
            show_menu
            ;;
    esac
}

# نمایش منو اصلی
show_menu
