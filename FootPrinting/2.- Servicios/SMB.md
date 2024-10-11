


[Server Message Block](https://docs.microsoft.com/en-us/windows/win32/fileio/microsoft-smb-protocol-and-cifs-protocol-overview) (`SMB`) is a protocol responsible for transferring data between a client and a server in local area networks. It is used to implement file and directory sharing and printing services in Windows networks. SMB is often referred to as a file system, but it is not. SMB can be compared to `NFS` for Unix and Linux for providing drives on local networks.

SMB is also known as [Common Internet File System](https://cifs.com/) (`CIFS`). It is part of the SMB protocol and enables universal remote connection of multiple platforms such as Windows, Linux, or macOS. In addition, we will often encounter [Samba](https://wiki.samba.org/index.php/Main_Page), which is an open-source implementation of the above functions. For SMB, we can also use `hydra` again to try different usernames in combination with different passwords.



- conectarse (NULL)

```bash
smbclient -N -L //<FQDN/IP>
```

- conectarse a un share concreto

```bash
smbclient //<FQDN/IP>/<share>
```

- interactuar usando RPC

```bash
rpcclient -U "" <FQDN/IP>
```

- enumeración de usuarios

```bash
impacket-samrdump <FQDN/IP>
```

- enumeración de shares

```bash
smbmap -H <FQDN/IP>
```
```bash
crackmapexec smb <FQDN/IP> --shares -u '' -p '' #null session
```

- enumerar 

```bash
# `enum4linux` proporciona una vista completa del entorno SMB del sistema objetivo, lo cual es esencial para identificar posibles vulnerabilidades y garantizar que los servicios SMB estén adecuadamente seguros.

enum4linux-ng <FQDN/IP> -A
```
- escanear red en busca de hosts

```sh
nbtscan -r 192.168.0.1/24
```

- versión del servidor

```sh
msf auxiliary/scanner/smb/smb_version
```


```sh
#!/bin/sh

#Description:
# Requires root or enough permissions to use tcpdump
# Will listen for the first 7 packets of a null login
# and grab the SMB Version
#Notes:
# Will sometimes not capture or will print multiple
# lines. May need to run a second time for success.
if [ -z $1 ]; then echo "Usage: ./smbver.sh RHOST {RPORT}" && exit; else rhost=$1; fi
if [ ! -z $2 ]; then rport=$2; else rport=139; fi
tcpdump -s0 -n -i tap0 src $rhost and port $rport -A -c 7 2>/dev/null | grep -i "samba\|s.a.m" | tr -d '.' | grep -oP 'UnixSamba.*[0-9a-z]' | tr -d '\n' & echo -n "$rhost: " &
echo "exit" | smbclient -L $rhost 1>/dev/null 2>/dev/null
echo "" && sleep .1
```


