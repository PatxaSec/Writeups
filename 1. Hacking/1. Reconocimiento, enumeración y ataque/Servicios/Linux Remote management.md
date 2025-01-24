
- Remote security audit

```sh
ssh-audit <FQDN/IP>
```

- log in

```sh
ssh <user>@<FQDN/IP>
```

- log in (Private-key)

```sh
ssh -i private.key <user>@<FQDN/IP>
```

- log in forzando passwd

```sh
ssh <user>@<FQDN/IP> -o PreferredAuthentications=password
```
