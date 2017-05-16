package main

import (
	"bytes"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/user"
	"path"
	"strings"

	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/knownhosts"
)

var (
	sshUsername = flag.String("username", "vagrant", "ssh username")
	sshPassword = flag.String("password", "", "ssh password")
	sshServer = flag.String("addr", "10.10.10.100:22", "ssh server address:port")
	sshKeyFile = flag.String("keyFile", "", "ssh client private key")
	sshKnownHostsFile = flag.String("knownHostsFile", "~/.ssh/known_hosts", "ssh known hosts")
	commandStdin = flag.String("stdin", "", "data to pass into the command stdin")
	command = flag.String("command", "whoami /all", "command to execute")
	hostKeyCallback ssh.HostKeyCallback
)

func main() {
	log.SetOutput(os.Stdout) // for not disturbing PowerShell...

	flag.Parse()

	expandTildePath(sshKeyFile)
	expandTildePath(sshKnownHostsFile)

	hkc, err := knownhosts.New(*sshKnownHostsFile)
	if err != nil {
		log.Fatalf("Failed to load the ssh %s known hosts file: %v", *sshKnownHostsFile, err)
	}
	hostKeyCallback = hkc

	log.Printf("Executing the %s command...", *command)

	output := executeCommand(*commandStdin, *command)

	log.Printf("Command output: %s", output)
}

func expandTildePath(p *string) {
	if strings.HasPrefix(*p, "~/") {
		u, err := user.Current()
		if err != nil {
			log.Fatalf("Failed to get current user: %v", err)
		}
		*p = path.Join(u.HomeDir, (*p)[2:])
	}
}

func executeCommand(stdin string, command string) string {
	config := &ssh.ClientConfig{
		User: *sshUsername,
		Auth: []ssh.AuthMethod{},
		HostKeyCallback: hostKeyCallback,
	}

	if *sshKeyFile != "" {
		key, err := ioutil.ReadFile(*sshKeyFile)
		if err != nil {
			return fmt.Sprintf("unable to read private key: %v", err)
		}

		signer, err := ssh.ParsePrivateKey(key)
		if err != nil {
			return fmt.Sprintf("unable to parse private key: %v", err)
		}

		config.Auth = append(config.Auth, ssh.PublicKeys(signer))
	}

	if *sshPassword != "" {
		config.Auth = append(config.Auth, ssh.Password(*sshPassword))
	}

	log.Printf("Connecting to %s...", *sshServer)

	client, err := ssh.Dial("tcp", *sshServer, config)
	if err != nil {
		return fmt.Sprintf("unable to connect: %v", err)
	}
	defer client.Close()

	log.Printf("Connected from %s (%s) to %s (%s)",
		client.LocalAddr(),
		client.ClientVersion(),
		client.RemoteAddr(),
		client.ServerVersion())

	log.Printf("Creating SSH session to %s...", *sshServer)

	session, err := client.NewSession()
	if err != nil {
		return fmt.Sprintf("Failed to create session: %v", err)
	}
	defer session.Close()

	if stdin != "" {
		session.Stdin = bytes.NewBufferString(stdin)
	}

	output, err := session.CombinedOutput(command)
	if err != nil {
		return fmt.Sprintf("Failed to run command: %v", err)
	}

	return string(output)
}
