
---


[hping3 | Kali Linux Tools](https://www.kali.org/tools/hping3/)


### ICMP Ping

```
hping3 -1 <ip>
```
### ACK scan port 80

```
hping3 -A <ip> -p 80
```

### UDP scan port 80

```
hping3 -2 <ip> -p 80
```

### Collect initial secuence number

```
hping3 <ip> -Q -p 139 -a
```
### Firewalls and Timestamp

```
hping3 -s <ip> -p 80 --tcp-timestamp
```

### SYN scan port 80

```
hping3 -8 
```

### FIN, PUSH and URG scan port 80

```
hping3 -F -P -U <ip> -p 80
```

### scan entire subnet



