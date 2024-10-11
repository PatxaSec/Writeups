
- Realizar escaneos para saber servicios y componentes

```sh
./odat.py all -s <FQDN/IP>
```

- log in

```sh
sqlplus <user>/<pass>@<FQDN/IP>/<db>
```

- Subir archivo

```sh
./odat.py utlfile -s <FQDN/IP> -d <db> -U <user> -P <pass> --sysdba --putFile C:\\insert\\path file.txt ./file.txt
```


