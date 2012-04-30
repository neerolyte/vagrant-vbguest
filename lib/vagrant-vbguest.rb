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
    Vagrant.actions[:start].use VagrantVbguest::Action
    # I would really like to do this:
    # action(:start) {
    #   use VagrantVbguest::Action
    # }
  end
end