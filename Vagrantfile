# to make sure the sshd node is created before the other nodes, we
# have to force a --no-parallel execution.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

config_sshd_fqdn    = 'sshd.example.com'
config_sshd_ip      = '10.10.10.100'
config_windows_fqdn = "windows.#{config_sshd_fqdn}"
config_windows_ip   = '10.10.10.102'

Vagrant.configure('2') do |config|
  config.vm.provider :libvirt do |lv, config|
    lv.cpus = 2
    lv.memory = 2048
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'smb', smb_username: ENV['USER'], smb_password: ENV['VAGRANT_SMB_PASSWORD']
  end

  config.vm.define :sshd do |config|
    config.vm.box = 'windows-2022-amd64'
    config.vm.hostname = 'sshd'
    config.vm.network :private_network, ip: config_sshd_ip, libvirt__forward_mode: 'none', libvirt__dhcp_enabled: false
    config.vm.provision :shell, path: 'ps.ps1', args: 'provision-common.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'provision-powershell.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'provision.ps1'
    config.vm.provision :shell, inline: "echo 'Rebooting...'", reboot: true
  end

  config.trigger.after :up do |trigger|
    trigger.only_on = 'sshd'
    trigger.run = {inline: 'chmod 600 tmp/id_rsa'} unless ENV['OS'] == 'Windows_NT'
  end

  config.vm.define :windows do |config|
    config.vm.box = 'windows-2022-amd64'
    config.vm.hostname = 'windows'
    config.vm.network :private_network, ip: config_windows_ip, libvirt__forward_mode: 'none', libvirt__dhcp_enabled: false
    config.vm.provision :shell, inline: "echo '#{config_sshd_ip} #{config_sshd_fqdn}' | Out-File -Encoding ASCII -Append c:/Windows/System32/drivers/etc/hosts"
    config.vm.provision :shell, path: 'ps.ps1', args: 'provision-common.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'provision-powershell.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'provision-windows.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'examples/powershell/cygwin.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'examples/powershell/native.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'examples/go/run.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'examples/python/run.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'examples/ruby/run.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'examples/csharp/run.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'examples/java/run.ps1'
    config.vm.provision :shell, path: 'ps.ps1', args: 'examples/ssh-audit/run.ps1'
  end
end
