This is a vagrant environment to test the [PowerShell/Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH) service,
which intents to be integrated into the upstream [Portable OpenSSH](https://github.com/openssh/openssh-portable) project
as the native SSHD for Windows.

In this environment you'll also find [several language examples](examples/) on how to access a machine through SSH. 

# Usage

[Build and install the Windows 2022 base image](https://github.com/rgl/windows-vagrant).

Launch the SSH server machine:

```bash
vagrant up sshd --no-destroy-on-error
```

**NB** this step will also create a SSH key at `tmp/ida_rsa` which we will later use to connect to the `vagrant` account.

See the allocated SSH port:

```bash
vagrant ssh-config sshd
```

You should see something like:

```plain
Host sshd
  HostName 127.0.0.1
  User vagrant
  Port 2222
  ...
```

Try accessing the ssh server at that port with the created SSH key:

```bash
ssh -i tmp/id_rsa vagrant@127.0.0.1 -p 2222 "whoami /all"
```

Now try the same, but from within the Windows Client machine. First launch it:

```bash
vagrant up windows --no-destroy-on-error
```

Then login into the Windows Desktop, and inside a PowerShell window run:

```powershell
&'C:/Program Files/OpenSSH/ssh' -i c:/vagrant/tmp/id_rsa vagrant@sshd.example.com "whoami /all"
```

List this repository dependencies (and which have newer versions):

```bash
export GITHUB_COM_TOKEN='YOUR_GITHUB_PERSONAL_TOKEN'
./renovate.sh
```

# sshd audit

<pre><span style="color: #00ffff"># general</span>
<span style="color: #00ff00">(gen) banner: SSH-2.0-OpenSSH_for_Windows_9.8 Win32-OpenSSH-GitHub</span>
<span style="color: #00ff00">(gen) compatibility: OpenSSH 9.6+, Dropbear SSH 2020.79+</span>
<span style="color: #00ff00">(gen) compression: enabled (zlib@openssh.com)</span>

<span style="color: #00ffff"># key exchange algorithms</span>
<span style="color: #00ff00">(kex) curve25519-sha256                     -- [info] available since OpenSSH 7.4, Dropbear SSH 2018.76</span>
<span style="color: #00ff00">                                            `- [info] default key exchange from OpenSSH 7.4 to 8.9</span>
<span style="color: #00ff00">(kex) curve25519-sha256@libssh.org          -- [info] available since OpenSSH 6.4, Dropbear SSH 2013.62</span>
<span style="color: #00ff00">                                            `- [info] default key exchange from OpenSSH 6.5 to 7.3</span>
<span style="color: #ff0000">(kex) ecdh-sha2-nistp256                    -- [fail] using elliptic curves that are suspected as being backdoored by the U.S. National Security Agency</span>
                                            `- [info] available since OpenSSH 5.7, Dropbear SSH 2013.62
<span style="color: #ff0000">(kex) ecdh-sha2-nistp384                    -- [fail] using elliptic curves that are suspected as being backdoored by the U.S. National Security Agency</span>
                                            `- [info] available since OpenSSH 5.7, Dropbear SSH 2013.62
<span style="color: #ff0000">(kex) ecdh-sha2-nistp521                    -- [fail] using elliptic curves that are suspected as being backdoored by the U.S. National Security Agency</span>
                                            `- [info] available since OpenSSH 5.7, Dropbear SSH 2013.62
<span style="color: #00ff00">(kex) diffie-hellman-group-exchange-sha256 (3072-bit) -- [info] available since OpenSSH 4.4</span>
<span style="color: #00ff00">                                                      `- [info] OpenSSH's GEX fallback mechanism was triggered during testing. Very old SSH clients will still be able to create connections using a 2048-bit modulus, though modern clients will use 3072. This can only be disabled by recompiling the code (see https://github.com/openssh/openssh-portable/blob/V_9_4/dh.c#L477).</span>
<span style="color: #00ff00">(kex) diffie-hellman-group16-sha512         -- [info] available since OpenSSH 7.3, Dropbear SSH 2016.73</span>
<span style="color: #00ff00">(kex) diffie-hellman-group18-sha512         -- [info] available since OpenSSH 7.3</span>
<span style="color: #ffff00">(kex) diffie-hellman-group14-sha256         -- [warn] 2048-bit modulus only provides 112-bits of symmetric strength</span>
                                            `- [info] available since OpenSSH 7.3, Dropbear SSH 2016.73
<span style="color: #00ff00">(kex) ext-info-s                            -- [info] available since OpenSSH 9.6</span>
<span style="color: #00ff00">                                            `- [info] pseudo-algorithm that denotes the peer supports RFC8308 extensions</span>
<span style="color: #00ff00">(kex) kex-strict-s-v00@openssh.com          -- [info] pseudo-algorithm that denotes the peer supports a stricter key exchange method as a counter-measure to the Terrapin attack (CVE-2023-48795)</span>

<span style="color: #00ffff"># host-key algorithms</span>
<span style="color: #00ff00">(key) rsa-sha2-512 (3072-bit)               -- [info] available since OpenSSH 7.2</span>
<span style="color: #00ff00">(key) rsa-sha2-256 (3072-bit)               -- [info] available since OpenSSH 7.2, Dropbear SSH 2020.79</span>
<span style="color: #ff0000">(key) ecdsa-sha2-nistp256                   -- [fail] using elliptic curves that are suspected as being backdoored by the U.S. National Security Agency</span>
<span style="color: #ffff00">                                            `- [warn] using weak random number generator could reveal the key</span>
                                            `- [info] available since OpenSSH 5.7, Dropbear SSH 2013.62
<span style="color: #00ff00">(key) ssh-ed25519                           -- [info] available since OpenSSH 6.5, Dropbear SSH 2020.79</span>

<span style="color: #00ffff"># encryption algorithms (ciphers)</span>
<span style="color: #00ff00">(enc) chacha20-poly1305@openssh.com         -- [info] available since OpenSSH 6.5, Dropbear SSH 2020.79</span>
<span style="color: #00ff00">                                            `- [info] default cipher since OpenSSH 6.9</span>
<span style="color: #00ff00">(enc) aes128-ctr                            -- [info] available since OpenSSH 3.7, Dropbear SSH 0.52</span>
<span style="color: #00ff00">(enc) aes192-ctr                            -- [info] available since OpenSSH 3.7</span>
<span style="color: #00ff00">(enc) aes256-ctr                            -- [info] available since OpenSSH 3.7, Dropbear SSH 0.52</span>
<span style="color: #00ff00">(enc) aes128-gcm@openssh.com                -- [info] available since OpenSSH 6.2</span>
<span style="color: #00ff00">(enc) aes256-gcm@openssh.com                -- [info] available since OpenSSH 6.2</span>

<span style="color: #00ffff"># message authentication code algorithms</span>
<span style="color: #ffff00">(mac) umac-64-etm@openssh.com               -- [warn] using small 64-bit tag size</span>
                                            `- [info] available since OpenSSH 6.2
<span style="color: #00ff00">(mac) umac-128-etm@openssh.com              -- [info] available since OpenSSH 6.2</span>
<span style="color: #00ff00">(mac) hmac-sha2-256-etm@openssh.com         -- [info] available since OpenSSH 6.2</span>
<span style="color: #00ff00">(mac) hmac-sha2-512-etm@openssh.com         -- [info] available since OpenSSH 6.2</span>
<span style="color: #ffff00">(mac) umac-64@openssh.com                   -- [warn] using encrypt-and-MAC mode</span>
<span style="color: #ffff00">                                            `- [warn] using small 64-bit tag size</span>
                                            `- [info] available since OpenSSH 4.7
<span style="color: #ffff00">(mac) umac-128@openssh.com                  -- [warn] using encrypt-and-MAC mode</span>
                                            `- [info] available since OpenSSH 6.2
<span style="color: #ffff00">(mac) hmac-sha2-256                         -- [warn] using encrypt-and-MAC mode</span>
                                            `- [info] available since OpenSSH 5.9, Dropbear SSH 2013.56
<span style="color: #ffff00">(mac) hmac-sha2-512                         -- [warn] using encrypt-and-MAC mode</span>
                                            `- [info] available since OpenSSH 5.9, Dropbear SSH 2013.56

<span style="color: #00ffff"># fingerprints</span>
<span style="color: #00ff00">(fin) ssh-ed25519: SHA256:REDACTED</span>
<span style="color: #00ff00">(fin) ssh-rsa: SHA256:REDACTED</span>

<span style="color: #00ffff"># additional info</span>
<span style="color: #ffff00">(nfo) Be aware that, while this target properly supports the strict key exchange method (via the kex-strict-?-v00@openssh.com marker) needed to protect against the Terrapin vulnerability (CVE-2023-48795), all peers must also support this feature as well, otherwise the vulnerability will still be present.  The following algorithms would allow an unpatched peer to create vulnerable SSH channels with this target: chacha20-poly1305@openssh.com.  If any CBC ciphers are in this list, you may remove them while leaving the *-etm@openssh.com MACs in place; these MACs are fine while paired with non-CBC cipher types.</span>
</pre>
