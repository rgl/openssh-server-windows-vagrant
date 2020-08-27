using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using CommandLine;
using Renci.SshNet;
using Renci.SshNet.Common;

namespace ExecuteCommand
{
    class Program
    {
        private class Options
        {
            [Option(
                Default="sshd.example.com:22",
                HelpText="ssh server address:port")]
            public string Addr { get; set; }

            [Option(
                Default="vagrant",
                HelpText="ssh username")]
            public string Username { get; set; }
            
            [Option(
                Default="vagrant",
                HelpText="ssh user password")]
            public string Password { get; set; }
            
            [Option(
                Default="c:/vagrant/tmp/id_rsa",
                HelpText="ssh client private key path")]
            public string KeyFile { get; set; }
            
            [Option(
                Default="whoami /all",
                HelpText="command to execute")]
            public string Command { get; set; }
        }

        static int Main(string[] args)
        {
            return Parser.Default.ParseArguments<Options>(args)
                .MapResult(Run, _ => 1);
        }

        static int Run(Options options)
        {
            var hostname = Regex.Replace(options.Addr, @":\d+$", "");
            var port = int.Parse(Regex.Replace(options.Addr, @"^.+?:", ""));

            var authenticationMethods = new List<AuthenticationMethod>();

            if (!string.IsNullOrEmpty(options.KeyFile))
            {
                authenticationMethods.Add(new PrivateKeyAuthenticationMethod(options.KeyFile));
            }

            if (!string.IsNullOrEmpty(options.Password))
            {
                authenticationMethods.Add(new PasswordAuthenticationMethod(options.Username, options.Password));
            }

            var connectionInfo = new ConnectionInfo(hostname, port, options.Username, authenticationMethods.ToArray());

            /*
            var connectionInfo = !string.IsNullOrEmpty(options.KeyFile)
                ? (ConnectionInfo)new PrivateKeyConnectionInfo(hostname, port, options.Username, new PrivateKeyFile(options.KeyFile))
                : (ConnectionInfo)new PasswordConnectionInfo(hostname, port, options.Username, options.Password);
            */

            using (var client = new SshClient(connectionInfo))
            {
                client.HostKeyReceived += (object sender, HostKeyEventArgs e) =>
                {
                    // NB by default the host key is trusted without any validation.
                    // NB e.FingerPrint is MD5(HostKey).

                    Console.WriteLine($"TODO validate the {options.Addr} host key {e.HostKeyName} {BitConverter.ToString(e.HostKey).Replace("-", "").ToLowerInvariant()}!");
                    Console.WriteLine($"{options.Addr} key CanTrust? {e.CanTrust}");
                };

                Console.WriteLine($"Connecting to {options.Addr}...");
                client.Connect();
                Console.WriteLine($"Connected to {options.Addr} ({connectionInfo.ServerVersion}) from ({connectionInfo.ClientVersion})!");
                Console.WriteLine($"Running command {options.Command}...");
                using (var c = client.RunCommand(options.Command))
                {
                    Console.WriteLine(c.Result);
                    Console.WriteLine($"command {options.Command} exited with status code {c.ExitStatus}");
                }
                Console.WriteLine($"Disconnecting from {options.Addr}...");
                client.Disconnect();
            }

            return 0;
        }
    }
}
