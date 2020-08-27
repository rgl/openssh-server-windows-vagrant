require 'net/ssh'

hostname = 'sshd.example.com'
port = 22
username = 'vagrant'
password = 'vagrant'
key_filename = 'c:/vagrant/tmp/id_rsa'
command = 'whoami /all'

puts "connecting to #{hostname}:#{port}..."
Net::SSH.start(
        hostname,
        username,
        :config => false,
        :port => port,
        :password => password,
        :keys => [key_filename],
        :verify_host_key => :always, # validate the server key against ~/.ssh/known_hosts
        :non_interactive => true
    ) do |ssh| # ssh is-a Net::SSH::Connection::Session
    puts "connected to #{ssh.transport.socket.peer_ip} (#{ssh.transport.server_version.version})"
    puts "executing the #{command} command..."
    puts ssh.exec! command
end
