package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/user"
	"path"
	"strings"

	packerSSH "github.com/hashicorp/packer-plugin-sdk/sdk-internals/communicator/ssh"
	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/knownhosts"
)

var (
	sshUsername       = flag.String("username", "vagrant", "ssh username")
	sshPassword       = flag.String("password", "", "ssh password")
	sshServer         = flag.String("addr", "sshd.example.com:22", "ssh server address:port")
	sshKeyFile        = flag.String("keyFile", "~/.ssh/id_rsa", "ssh client private key")
	sshKnownHostsFile = flag.String("knownHostsFile", "~/.ssh/known_hosts", "ssh known hosts")
	sourceFile        = flag.String("sourceFile", "", "source file")
	destinationFile   = flag.String("destinationFile", "", "destination file")
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

	log.Printf("Uploading the %s file into %s...", *sourceFile, *destinationFile)

	err = uploadFile(*sourceFile, *destinationFile)
	if err != nil {
		log.Fatalf("failed to upload file: %v", err)
	}
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

func uploadFile(sourceFile string, destinationFile string) error {
	config := &ssh.ClientConfig{
		User:            *sshUsername,
		Auth:            []ssh.AuthMethod{},
		HostKeyCallback: hostKeyCallback,
	}

	if *sshPassword != "" {
		config.Auth = append(config.Auth, ssh.Password(*sshPassword))
	} else if *sshKeyFile != "" {
		key, err := os.ReadFile(*sshKeyFile)
		if err != nil {
			return fmt.Errorf("unable to read private key: %w", err)
		}

		signer, err := ssh.ParsePrivateKey(key)
		if err != nil {
			return fmt.Errorf("unable to parse private key: %w", err)
		}

		config.Auth = append(config.Auth, ssh.PublicKeys(signer))
	}

	comm, err := packerSSH.New(*sshServer, &packerSSH.Config{
		Connection: packerSSH.ConnectFunc("tcp", *sshServer),
		SSHConfig:  config,
	})
	if err != nil {
		return fmt.Errorf("unable to connect: %w", err)
	}

	source, err := os.Open(sourceFile)
	if err != nil {
		return fmt.Errorf("unable to open source file %s: %w", sourceFile, err)
	}
	defer source.Close()

	sourceInfo, err := source.Stat()
	if err != nil {
		return fmt.Errorf("unable to stat source file %s: %w", sourceFile, err)
	}

	err = comm.Upload(destinationFile, source, &sourceInfo)
	if err != nil {
		return fmt.Errorf("unable to upload file: %v", err)
	}

	return nil
}
