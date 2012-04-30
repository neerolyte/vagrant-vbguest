module VagrantVbguest
  
  class Config < Vagrant::Config::Base
    attr_accessor :iso_path, :auto_update, :installer, :no_install, :no_remote

    def validate(env, errors)
      if !installer.nil? && (!installer.is_a?(Class) || installer <= Installer::Base)
        errors.add I18n.t("vagrant.plugins.vbguest.invalid_installer_class") 
      end
    end
    
    def auto_update; @auto_update.nil? ? (@auto_update = true) : @auto_update; end
    def no_remote; @no_remote.nil? ? (@no_remote = false) : @no_remote; end
    def no_install; @no_install.nil? ? (@no_install = false): @no_install; end
    
    # explicit hash, to get symbols in hash keys
    def to_hash
      {
        :iso_path => iso_path,
        :auto_update => auto_update,
        :installer => installer,
        :no_install => no_install,
        :no_remote => no_remote
      }
    end
    
  end
end
