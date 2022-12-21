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
	sshUsername       = flag.String("username", "vagrant", "ssh username")
	sshPassword       = flag.String("password", "", "ssh password")
	sshServer         = flag.String("addr", "sshd.example.com:22", "ssh server address:port")
	sshKeyFile        = flag.String("keyFile", "~/.ssh/id_rsa", "ssh client private key")
	sshKnownHostsFile = flag.String("knownHostsFile", "~/.ssh/known_hosts", "ssh known hosts")
	commandStdin      = flag.String("stdin", "", "data to pass into the command stdin")
	command           = flag.String("command", "whoami /all", "command to execute")
	hostKeyCallback   ssh.HostKeyCallback
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

	exitCode, output, err := executeCommand(*commandStdin, *command)
	if err != nil {
		log.Fatalf("failed to execute command: %v", err)
	}

	log.Printf("Command ended with exit code %d and output:\n%s", exitCode, output)

	os.Exit(exitCode)
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

func executeCommand(stdin string, command string) (int, string, error) {
	config := &ssh.ClientConfig{
		User:            *sshUsername,
		Auth:            []ssh.AuthMethod{},
		HostKeyCallback: hostKeyCallback,
	}

	if *sshPassword != "" {
		config.Auth = append(config.Auth, ssh.Password(*sshPassword))
	} else if *sshKeyFile != "" {
		key, err := ioutil.ReadFile(*sshKeyFile)
		if err != nil {
			return -1, "", fmt.Errorf("unable to read private key: %w", err)
		}

		signer, err := ssh.ParsePrivateKey(key)
		if err != nil {
			return -1, "", fmt.Errorf("unable to parse private key: %w", err)
		}

		config.Auth = append(config.Auth, ssh.PublicKeys(signer))
	}

	log.Printf("Connecting to %s...", *sshServer)

	client, err := ssh.Dial("tcp", *sshServer, config)
	if err != nil {
		return -1, "", fmt.Errorf("unable to connect: %w", err)
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
		return -1, "", fmt.Errorf("failed to create session: %w", err)
	}
	defer session.Close()

	if stdin != "" {
		session.Stdin = bytes.NewBufferString(stdin)
	}

	output, err := session.CombinedOutput(command)
	if err != nil {
		if e, ok := err.(*ssh.ExitError); ok {
			return e.ExitStatus(), string(output), nil
		}
		return -1, "", fmt.Errorf("failed to run command: %w", err)
	}

	return 0, string(output), nil
}
