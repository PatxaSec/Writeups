
- revisar configuración de seguridad

```sh
rdp-sec-check.pl <FQDN/IP>
```

- log in desde Linux

```sh
xfreerdp /u:<user> /p:"<password>" /v:<FQDN/IP>
```

- log in a WinRM

```sh
evil-winrm -i <FQDN/IP> -u <user> -p <password>
```

- ejecutar comandos 

```sh
wmiexec.py <user>:"<password>"@<FQDN/IP> "<system command>"
```
