# Returns true if we are running on a MS windows platform, false otherwise.
def Kernel.is_windows?
  processor, platform, *rest = RUBY_PLATFORM.split("-")
  platform == 'mswin32' or platform == 'mingw32'
end


Vagrant.configure("2") do |config|
	config.vm.box = "Puppetlabs Debian 7.0rc1 x86_64, VBox 4.2.10"
	config.vm.box_url = "http://puppet-vagrant-boxes.puppetlabs.com/debian-70rc1-x64-vbox4210.box"
	config.vm.network :public_network
	config.vm.network :private_network, ip: "10.20.50.2"

	config.vm.network :forwarded_port, guest: 3000, host: 3000
	config.vm.network :forwarded_port, guest: 5432, host: 2345

	is_windows = Kernel.is_windows?

	if !is_windows
		config.vm.synced_folder ".", "/vagrant", :nfs => true, :id => 'vagrant-root'
	else
		config.vm.synced_folder ".", "/vagrant", :id => 'vagrant-root'
	end

	config.vm.provision :puppet do |puppet|
		# Below is useful for debugging
		puppet.module_path = "puppet/modules"
		puppet.manifests_path = "puppet/manifests"
		puppet.options = "--verbose --debug"
	end
end
