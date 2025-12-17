#!/bin/bash
iface=$(ip route | awk '/default/ {print $5; exit}')

rx1=$(cat /sys/class/net/$iface/statistics/rx_bytes)
tx1=$(cat /sys/class/net/$iface/statistics/tx_bytes)
sleep 1
rx2=$(cat /sys/class/net/$iface/statistics/rx_bytes)
tx2=$(cat /sys/class/net/$iface/statistics/tx_bytes)

down=$(( (rx2 - rx1) * 8 / 1000000 ))
up=$(( (tx2 - tx1) * 8 / 1000000 ))

if [[ -n "$iface" ]]; then
    echo "󰈀 ↓${down}Mb ↑${up}Mb"
else
    echo "󰤠 Disconnected"
fi
