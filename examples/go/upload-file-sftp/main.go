package main

import (
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"os/user"
	"path"
	"strings"

	"github.com/pkg/sftp"
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

	log.Printf("Connecting to %s...", *sshServer)

	client, err := ssh.Dial("tcp", *sshServer, config)
	if err != nil {
		return fmt.Errorf("unable to connect: %w", err)
	}
	defer client.Close()

	log.Printf("Connected from %s (%s) to %s (%s)",
		client.LocalAddr(),
		client.ClientVersion(),
		client.RemoteAddr(),
		client.ServerVersion())

	log.Printf("Starting the SFTP subsystem...")

	c, err := sftp.NewClient(client, sftp.MaxPacket(32*1024))
	if err != nil {
		return fmt.Errorf("unable to start the SFTP subsystem: %v", err)
	}
	defer c.Close()

	r, err := os.Open(sourceFile)
	if err != nil {
		return fmt.Errorf("unable to open source file: %w", err)
	}
	defer r.Close()

	w, err := c.Create(destinationFile)
	if err != nil {
		return fmt.Errorf("unable to create destination file: %w", err)
	}
	defer w.Close()

	log.Printf("Copying file...")

	_, err = io.Copy(w, r)
	if err != nil {
		return fmt.Errorf("unable to copy file: %w", err)
	}

	return err
}
