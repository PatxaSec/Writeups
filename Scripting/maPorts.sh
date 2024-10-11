#!/bin/bash

endColour="\033[0m\e[0m"
greenColour="\e[0;32m\033[1m"
yellowColour="\e[0;33m\033[1m"

audit(){
        mkdir $1; cd $1
        mkdir {enum,exploits}; cd enum
}

get_os() {
  if [[ "$(ping -c 1 $1 | grep 'ttl' | awk '{print $6}' | tr '=' ' ' | awk '{print $2}')" -le 64 ]]; then
            echo "[+] Linux"
        elif [[ "$(ping -c 1 $1 | grep 'ttl' | awk '{print $6}' | tr '=' ' ' | awk '{print $2}')" -ge 65 && "$(ping -c 1 $1 | grep 'ttl' | awk '{print $6}' | tr '=' ' ' | awk '{print $2}')" -le 128 ]]; then
            echo "[+] Windows"
        elif [[ "$(ping -c 1 $1 | grep 'ttl' | awk '{print $6}' | tr '=' ' ' | awk '{print $2}')" -gt 128 ]]; then
            echo "[+] Solaris/AIX"
        else
            echo "[!] Not Reached"
        fi
}

scan_ports() {
  nmap -p- -Pn -n $1 -oG "$2_$1.txt" > /dev/null 2>&1
  ports=$(cat "$2_$1".txt | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',' | tr -d '\n')
  ip_adress=$(cat "$2_$1".txt | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)
  echo -e "\n${greenColour}[*] Extracting information...\n"
  echo -e "\t${greenColour}[*] Open ports:  ${endColour} $ports\n"
  nmap -sV --script vuln -p $ports -Pn -n $1 -oN "vuln_$1_$2" > /dev/null 2>&1
}

progress_bar() {
  local process=$1
  local total=$2
  local percent=$(printf "%d" $(( (process*100) / total )))
  local filled=$(( (percent * 100) / 100))
  local remaining=$((100 - filled))
  printf "\r["
  printf "%0.s${greenColour}-${endColour}" $(seq 1 $filled)
  printf "%0.s${yellowColour} ${endColour}" $(seq 1 $remaining)
  printf "] %d%%" "$percent"
  printf "\n"
}

target=$1
nombre=$2

if [ -z "$target" ] || [ -z "$nombre" ]; then
  echo "Error: Debes proporcionar un objetivo y un nombre de archivo"
  exit 1
fi
if [ "$3" == "s" ]; then
  audit $nombre
else
  echo -e "${yellowColour}[!] Not created $2${endColour}"
  mkdir portscan
  cd portscan
fi
echo "Scanning..."
if [ -f "$target" ]; then
  total_lines=$(wc -l < "$target")
  count=0
  for ip in $(cat $target); do
    ((count++))
    progress_bar $count $total_lines
    echo ""
    os=$(get_os $ip)
    echo -e "${greenColour}Sistema Operativo:  ${endColour} $os"
    echo -e "${greenColour}Finding Open Ports on: ${endColour} $ip"
    echo "========================================================"
    scan_ports $ip $nombre
    echo -e "${greenColour}Escaneo completo. Archivos de salida generados: ${endColour}"
    echo -e "${greenColour}[+] $2_$1.txt (resultado del escaneo de puertos -oG) ${endColour}"
    echo -e "${greenColour}[+] vuln_$1_$2 (información de servicios y vulns) ${endColour}"
    echo "========================================================"
  done
  echo ""
else
  os=$(get_os $target)
  echo -e "${greenColour}Sistema Operativo:  ${endColour} $os"
  echo -e "${greenColour}Finding Open Ports on: ${endColour} $target"
  scan_ports $target $nombre
  echo -e "${greenColour}Escaneo completo. Archivos de salida generados: ${endColour}"
  echo -e "${greenColour}[+] $2_$1.txt (resultado del escaneo de puertos -oG) ${endColour}"
  echo -e "${greenColour}[+] vuln_$1_$2 (información de servicios y vulns) ${endColour}"
fi


