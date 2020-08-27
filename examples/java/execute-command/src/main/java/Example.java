import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import net.schmizz.sshj.SSHClient;
import net.schmizz.sshj.common.IOUtils;
import net.schmizz.sshj.common.SecurityUtils;
import net.schmizz.sshj.connection.channel.direct.Session;
import net.schmizz.sshj.connection.channel.direct.Session.Command;
import java.io.File;

public class Example {
    public static class Args {
        @Parameter(names = "--hostname", description="ssh hostname")
        public String hostname = "sshd.example.com";

        @Parameter(names = "--port", description="ssh port")
        public int port = 22;

        @Parameter(names = "--username", description="ssh username")
        public String username = "vagrant";

        @Parameter(names = "--password", description="ssh password")
        public String password;

        @Parameter(names = "--key-file", description="ssh client private key")
        String keyFile = null;

        @Parameter(names = "--known-hosts-file", description="ssh known hosts")
        String knownHostsFile = "~/.ssh/known_hosts";

        @Parameter(names = "--command", description="command to execute")
        String command = "whoami /all";
    }

    public static void main(String[] argv) throws Exception {
        System.out.printf("running with Unlimited Strength Jurisdiction Policy? %b%n", javax.crypto.Cipher.getMaxAllowedKeyLength("AES") == Integer.MAX_VALUE);
        //java.security.Security.addProvider(new org.bouncycastle.jce.provider.BouncyCastleProvider());
        System.out.printf("running with Bouncy Castle? %b%n", SecurityUtils.isBouncyCastleRegistered());

        Args args = new Args();
        JCommander.newBuilder()
            .addObject(args)
            .build()
            .parse(argv);

        try (SSHClient ssh = new SSHClient()) {
            ssh.loadKnownHosts(new File(expandTildePath(args.knownHostsFile)));
            ssh.connect(args.hostname, args.port);
            if (args.password != null) {
                ssh.authPassword(args.username, args.password);
            } else {
                ssh.authPublickey(args.username, expandTildePath(args.keyFile));
            }

            System.out.printf("client version: %s%n", ssh.getTransport().getClientVersion());
            System.out.printf("server version: %s%n", ssh.getTransport().getServerVersion());

            try (Session session = ssh.startSession()) {
                Command command = session.exec(args.command);
                String output = IOUtils.readFully(command.getInputStream()).toString("UTF-8");
                command.join();
                int exitCode = command.getExitStatus();
                System.out.println(output);
                System.out.printf("command exited with code %d%n", exitCode);
            }
        }
    }

    private static String expandTildePath(String p) {
        if (p != null && p.startsWith("~/")) {
            p = System.getProperty("user.home") + "/" + p.substring(2);
        }
        return p;
    }
}
