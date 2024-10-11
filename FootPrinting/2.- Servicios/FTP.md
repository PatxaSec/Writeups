
- Conectarse

```bash
ftp <FQDN/IP> (anonimo)

ftp://anonymous:anonymous@10.10.10.98
```

```bash
nc -nv <FQDN/IP> 21
```


```bash
telnet <FQDN/IP> 21
```

- Conectarse con conexión cifrada


```bash
openssl s_client -connect <FQDN/IP>:21 -starttls ftp
```

- Descargarse los archivos disponibles del objetivo

```bash
wget -m --no-passive ftp://anonymous:anonymous@<target>
```

#### Archivos de configuración

```
ftpusers
ftp.conf
proftpd.conf
vsftpd.conf
```
#### HackTricks

```
Protocol_Name: FTP    #Protocol Abbreviation if there is one.
Port_Number:  21     #Comma separated if there is more than one.
Protocol_Description: File Transfer Protocol          #Protocol Abbreviation Spelled out

Entry_1:
Name: Notes
Description: Notes for FTP
Note: |
Anonymous Login
-bi     <<< so that your put is done via binary

wget --mirror 'ftp://ftp_user:UTDRSCH53c"$6hys@10.10.10.59'
^^to download all dirs and files

wget --no-passive-ftp --mirror 'ftp://anonymous:anonymous@10.10.10.98'
if PASV transfer is disabled

https://book.hacktricks.xyz/pentesting/pentesting-ftp

Entry_2:
Name: Banner Grab
Description: Grab FTP Banner via telnet
Command: telnet -n {IP} 21

Entry_3:
Name: Cert Grab
Description: Grab FTP Certificate if existing
Command: openssl s_client -connect {IP}:21 -starttls ftp

Entry_4:
Name: nmap ftp
Description: Anon login and bounce FTP checks are performed
Command: nmap --script ftp-* -p 21 {IP}

Entry_5:
Name: Browser Connection
Description: Connect with Browser
Note: ftp://anonymous:anonymous@{IP}

Entry_6:
Name: Hydra Brute Force
Description: Need Username
Command: hydra -t 1 -l {Username} -P {Big_Passwordlist} -vV {IP} ftp

Entry_7:
Name: consolesless mfs enumeration ftp
Description: FTP enumeration without the need to run msfconsole
Note: sourced from https://github.com/carlospolop/legion
Command: msfconsole -q -x 'use auxiliary/scanner/ftp/anonymous; set RHOSTS {IP}; set RPORT 21; run; exit' && msfconsole -q -x 'use auxiliary/scanner/ftp/ftp_version; set RHOSTS {IP}; set RPORT 21; run; exit' && msfconsole -q -x 'use auxiliary/scanner/ftp/bison_ftp_traversal; set RHOSTS {IP}; set RPORT 21; run; exit' && msfconsole -q -x 'use auxiliary/scanner/ftp/colorado_ftp_traversal; set RHOSTS {IP}; set RPORT 21; run; exit' &&  msfconsole -q -x 'use auxiliary/scanner/ftp/titanftp_xcrc_traversal; set RHOSTS {IP}; set RPORT 21; run; exit'
```