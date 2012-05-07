require 'vagrant'
require 'vagrant-vbguest/errors'

require 'vagrant-vbguest/installer'
require 'vagrant-vbguest/installers/base'
require 'vagrant-vbguest/installers/linux'
require 'vagrant-vbguest/installers/debian'
require 'vagrant-vbguest/installers/ubuntu'

require 'vagrant-vbguest/action'
require 'vagrant-vbguest/config'
require 'vagrant-vbguest/command'

require 'vagrant-vbguest/detector'
require 'vagrant-vbguest/download'


# Add our custom translations to the load path
I18n.load_path << File.expand_path("../../locales/en.yml", __FILE__)

module VagrantVbguest

  class Plugin < Vagrant.plugin("1")
    name "vbguest management"
    description <<-DESC
    Provides automatic and/or manual management of the 
    VirtualBox Guest Additions inside the Vagrant environment.
    DESC

    config('vbguest') { Config }
    command('vbguest') { Command }
    
    # hook after anything that boots: 
    # that's all middlewares which will run the buildin "VM::Boot" action
    action_hook(Vagrant::Plugin::V1::ALL_ACTIONS) do |seq|
      if (idx = seq.index(Vagrant::Action::VM::Boot))
        seq.insert_after(idx, Action)
      end
    end
    
  end
end