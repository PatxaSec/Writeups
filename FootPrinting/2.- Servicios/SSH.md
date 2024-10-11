
[Secure Shell](https://www.ssh.com/academy/ssh/protocol) (`SSH`) is a more secure way to connect to a remote host to execute system commands or transfer files from a host to a server. The SSH server runs on `TCP port 22` by default, to which we can connect using an SSH client. This service uses three different cryptography operations/methods: `symmetric` encryption, `asymmetric` encryption, and `hashing`.

#### Symmetric Encryption

Symmetric encryption uses the `same key` for encryption and decryption. However, anyone who has access to the key could also access the transmitted data. Therefore, a key exchange procedure is needed for secure symmetric encryption. The [Diffie-Hellman](https://en.wikipedia.org/wiki/Diffie%E2%80%93Hellman_key_exchange) key exchange method is used for this purpose. If a third party obtains the key, it cannot decrypt the messages because the key exchange method is unknown. However, this is used by the server and client to determine the secret key needed to access the data. Many different variants of the symmetrical cipher system can be used, such as AES, Blowfish, 3DES, etc.

#### Asymmetrical Encryption

Asymmetric encryption uses `two SSH keys`: a private key and a public key. The private key must remain secret because only it can decrypt the messages that have been encrypted with the public key. If an attacker obtains the private key, which is often not password protected, he will be able to log in to the system without credentials. Once a connection is established, the server uses the public key for initialization and authentication. If the client can decrypt the message, it has the private key, and the SSH session can begin.

#### Hashing

The hashing method converts the transmitted data into another unique value. SSH uses hashing to confirm the authenticity of messages. This is a mathematical algorithm that only works in one direction.

#### Hydra - SSH

We can use a tool such as `Hydra` to brute force SSH. This is covered in-depth in the [Login Brute Forcing](https://academy.hackthebox.com/course/preview/login-brute-forcing/introduction-to-brute-forcing) module.

```shell-session
hydra -L user.list -P password.list ssh://10.129.42.197
```
