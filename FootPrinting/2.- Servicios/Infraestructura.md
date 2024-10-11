
#### Enumeración de infraestructura

- Certificados

```bash
curl -s https://crt.sh/\?q\=<target-domain>\&output\=json | jq .
```

- Buscar listado de IP en Shodan

```bash
for i in $(cat ip-addresses.txt);do shodan host $i;done
```
