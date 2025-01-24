
- conectarse anónimo

```sh
telnet <FQDN/IP> 25
```

```sh
nc -vn <IP> 25
```

- conectarse SMTPS

```sh
openssl s_client -crlf -connect smtp.mailgun.org:465 #SSL/TLS no starttls command

openssl s_client -starttls smtp -crlf -connect smtp.mailgun.org:587
```
- encontrar servidores MX

```sh
dig +short mx google.com
```

- Automático

```sh
Metasploit: auxiliary/scanner/smtp/smtp_enum
smtp-user-enum: smtp-user-enum -M <MODE> -u <USER> -t <IP>
Nmap: nmap --script smtp-enum-users <IP>
```
