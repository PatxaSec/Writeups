
- Consulta de OID 

```sh
snmpwalk -v2c -c <community string> <FQDN/IP>
```

- bruteforce  strings comunes

```sh
onesixtyone -c community-strings.list <FQDN/IP>
```

- bruteforce OIDs

```sh
braa <community string>@<FQDN/IP>:.1.*
```
#### HackTricks

```
Protocol_Name: SNMP    #Protocol Abbreviation if there is one.
Port_Number:  161     #Comma separated if there is more than one.
Protocol_Description: Simple Network Managment Protocol         #Protocol Abbreviation Spelled out

Entry_1:
Name: Notes
Description: Notes for SNMP
Note: |
SNMP - Simple Network Management Protocol is a protocol used to monitor different devices in the network (like routers, switches, printers, IoTs...).

https://book.hacktricks.xyz/pentesting/pentesting-snmp

Entry_2:
Name: SNMP Check
Description: Enumerate SNMP
Command: snmp-check {IP}

Entry_3:
Name: OneSixtyOne
Description: Crack SNMP passwords
Command: onesixtyone -c /usr/share/seclists/Discovery/SNMP/common-snmp-community-strings-onesixtyone.txt {IP} -w 100

Entry_4:
Name: Nmap
Description: Nmap snmp (no brute)
Command: nmap --script "snmp* and not snmp-brute" {IP}

Entry_5:
Name: Hydra Brute Force
Description: Need Nothing
Command: hydra -P {Big_Passwordlist} -v {IP} snmp
```
