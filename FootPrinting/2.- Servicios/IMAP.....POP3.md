
- log in IMAPS 

```sh
curl -k 'imaps://<FQDN/IP>' --user <user>:<password>
```

- conectarse IMAPS

```sh
openssl s_client -connect <FQDN/IP>:imaps

nc -nv <IP> 143

openssl s_client -connect <IP>:993 -quiet
```

- conectarse POP3s

```sh
openssl s_client -connect <FQDN/IP>:pop3s
```

- NTLM AUTH

```sh
telnet example.com 143
```
