
- Mostrar shares

```sh
showmount -e <FQDN/IP>
```

- montar un share especifico

```sh
mount -t nfs <FQDN/IP>:/<share> ./target-NFS/ -o nolock
```

- desmontar un share especifico

```sh
umount ./target-NFS
```

