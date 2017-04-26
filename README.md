This is a vagrant environment to test the [PowerShell/Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH) service,
which intents to be integrated into the upstream [Portable OpenSSH](https://github.com/openssh/openssh-portable) project
as the native SSHD for Windows.

In this environment you'll also find [several language examples](examples/) on how to access a machine through SSH. 

# Usage

[Build and install the base image](https://github.com/rgl/windows-2016-vagrant).

Launch the SSH server machine:

```bash
vagrant up sshd
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
ssh -i tmp/id_rsa vagrant@localhost -p 2222 "whoami /all"
```

Now try the same, but from within the Windows Client machine. First launch it:

```bash
vagrant up windows
```

Then login into the Windows Desktop through VirtualBox, and inside a PowerShell window run:

```powershell
c:/OpenSSH/ssh -i c:/vagrant/tmp/id_rsa vagrant@sshd.example.com "whoami /all"
```
