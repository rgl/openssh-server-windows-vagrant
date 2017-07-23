config_sshd_fqdn    = 'sshd.example.com'
config_sshd_ip      = '10.10.10.100'
config_windows_fqdn = "windows.#{config_sshd_fqdn}"
config_windows_ip   = '10.10.10.102'

Vagrant.configure('2') do |config|
  config.vm.provider :virtualbox do |v, override|
    v.linked_clone = true
    v.cpus = 2
    v.memory = 2048
    v.customize ['modifyvm', :id, '--vram', 64]
    v.customize ['modifyvm', :id, '--clipboard', 'bidirectional']
  end

  config.vm.define :sshd do |config|
    config.vm.box = 'windows-2016-amd64'
    config.vm.hostname = 'sshd'
    config.vm.network :private_network, ip: config_sshd_ip
    config.vm.provision :shell, path: 'ps.ps1', args: 'provision-common.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'provision.ps1'
    config.vm.provision :reload
  end

  config.trigger.after :up, :vm => 'sshd' do
    run 'chmod 600 tmp/id_rsa' unless ENV['OS'] == 'Windows_NT'
  end

  config.vm.define :windows do |config|
    config.vm.box = 'windows-2016-amd64'
    config.vm.hostname = 'windows'
    config.vm.network :private_network, ip: config_windows_ip
    config.vm.provision :shell, inline: "echo '#{config_sshd_ip} #{config_sshd_fqdn}' | Out-File -Encoding ASCII -Append c:/Windows/System32/drivers/etc/hosts"
    config.vm.provision :shell, path: 'ps.ps1', args: 'provision-common.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'provision-windows.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'examples/powershell/cygwin.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'examples/powershell/native.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'examples/go/run.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'examples/python/run.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'examples/csharp/run.ps1'
  end
end
