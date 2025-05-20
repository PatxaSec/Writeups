


```sh
alias ll='ls -l'
alias la='ls -a'
alias l='ls'
alias lla='ls -la'
alias bat='/bin/batcat --paging=never'
alias catnl='batcat'
alias wpscan='wpscan --api-token CTs9s71HT6zDBfzj2GncyypgU2LYvPtadLms5es0p38'


function audit(){
        mkdir $1; cd $1
        mkdir {enum,exploits}; cd enum
}

function ports(){
        ports="$(cat $1 | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
        ip_address="$(cat $1 | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)"
        echo -e "\n[*] Extracting information...\n" > extractPorts.tmp
        echo -e "\t[*] IP Address: $ip_address"  >> extractPorts.tmp
        echo -e "\t[*] Open ports: $ports\n"  >> extractPorts.tmp
        echo $ports | tr -d '\n' | xclip -sel clip
        echo -e "[*] Ports copied to clipboard\n"  >> extractPorts.tmp
        cat extractPorts.tmp; rm extractPorts.tmp; rm $1
}


function os(){
        p=$(ping -c 1 $1 | grep 'ttl' | awk '{print $6}' | tr '=' ' ' | awk '{print $2}')
        if [[ $p -le 64 && $p -ge 50 ]]; then
            echo "[+] Linux"
        elif [[ $p -ge 65 && $p -le 128 ]]; then
            echo "[+] Windows"
        elif [[ $p -gt 128 ]]; then
            echo "[+] Solaris/AIX"
        else
            echo "[!] Not Reached"
        fi
}
```
