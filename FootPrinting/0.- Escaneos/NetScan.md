


## localnet

- windows
```
arp -a
```
- linux
```
ip neigh
```
---

## Quick Host Discovery using ARP Protocol

**Using NETDISCOVER to perform an ARP scan:  
`sudo netdiscover -i **<interface>** -r **<targetSubnet>**`

**Using ARP-SCAN to perform an ARP scan:  
`sudo arp-scan -I **<interface>** **<targetSubnet>**`

---

## Identifying your Immediate Routes and Gateways

**Windows will show the default gateway:  
`ipconfig /all`

**In Linux, you can use TRACEROUTE:  
`traceroute **<targetIP>** -m 5`

**In Linux, you can look at the routing table:  
`route`

**To see which routes you may have access to:  
`ip route show dev **<interface>**`

---

## Portscanning with Nmap and Hping

### Nmap

**My go-to nmap command:  
`sudo nmap -sV -sC -p- **<ipAddr>** -oA nmap/top1000`

**Using Nmap for a pingsweep without port discovery:  
`sudo nmap -PE -sn -n **<ipRange>** -oA nmap/pingsweep`

**Using Nmap for pingsweep, with top 20 port discovery:  
`sudo nmap -PE -n **<ipRange>** --top-ports 20`

**Using Nmap to scan UDP ports:  
`sudo nmap -sU **<ipRange>**`

**Using Nmap for ARP Scan:  
`sudo nmap -PR -sn **<ipRange>**`

**Sometimes filtering may in place to only allow certain source ports on the network. To get around that, we could use the following Nmap command to scan DNS port 53 with a source port of 53:  
`sudo nmap -sS --source-port 53 -p 53 **<ipRange>** -oA nmap/dns-servers`

### Hping

**Hping is also useful as its always a good idea to get a 2nd opinion. The following will scan a specific port with 3 SYN packets.  
`sudo hping3 -S **<ipAddr>** -p **<port>** -c 3`

**To use Hping to scan a port range, but exclude port 525:  
`sudo hping3 -S --scan '80,445,500-550,!525' **<ipAddr>** -V`

**To use Hping for UDP scans:  
`sudo hping3 -2 --scan 1-1000 **<ipAddr>**`

**Sometimes filtering may in place to only allow certain source ports on the network. To get around that, we could use the following Hping command to scan DNS port 53 with a source port of 53:  
`sudo hping3 -S -s 53 -k -p 53 **<ipAddr>**`

---

## Host Enumeration Using FPing

**We can leverage fPing to do a quick search on the network for alive hosts.  
`fping -A **<targetIP>**`

**We can also add an option to limit the number of retries attempted, speeding up the execution.  
`fping -A **<targetIP>** -r 0`

**Adding another option will allow us to view the time it took to retrieve the reply.  
`fping -A **<targetIP>** -e`

**To sweep a network efficiently, without retires, and only display the alive hosts:  
`fping -q -a -g **10.0.0.0/24** -r 0 -e`

---

## From within a Meterpreter session:

**Display the network adapters and their associated IP addresses:  
`ifconfig`

**Display nearby machines on the network:  
`arp`

**Display entries on the local routing table:  
`route`

**Perform an ARP scan for a given IP range:  
`run arp_scanner -r 10.0.0.0/24`

**View existing configured routes in Metasploit:  
`route print`

**Forward specific port to a remote host, through the Meterpreter session. Any traffic send to the local port of our localsystem will route through the Meterpreter session.  
`portfwd add -l **<localPort>** -p **<remotePort>** **<destinationIP>**`

---

## Handy Metasploit modules:

**Run a ping sweep through a compromised system:  
`use post/multi/gather/ping_sweep`

**Configure a Metasploit route for pivoting:  
`use post/multi/manage/autoroute`

**You can also configure a route while interacting with a Meterpreter session:  
`run autoroute -s **<subnet>**`

**Run a TCP port scan (you may want to configure a route first):  
`use auxiliary/scanner/portscan/tcp`

**Configure a Socks4 proxy for pivoting. Any traffic routed through the proxy will route through the Metasploit routing table:  
`[https://infinitelogins.com/2021/02/20/using-metasploit-routing-and-proxychains-for-pivoting/](https://infinitelogins.com/2021/02/20/using-metasploit-routing-and-proxychains-for-pivoting/)`

---

## Windows Utilities (LOLbins)

**Display network adapters, DNS servers, and additional details:  
`ipconfig /all`

**Identify details about the DNS cache:  
`ipconfig /displaydns`

**To view details about ports and services on the system:  
`netstat -ano`

