module VagrantVbguest

  class IsoDetector

    def initialize(vm, options)
      @vm = vm
      @options = options
    end

    def iso_path
      @iso_path ||= autodetect_iso
    end

    private

      def autodetect_iso
        path = media_manager_iso || guess_iso || web_iso
        raise VagrantVbguest::IsoPathAutodetectionError if !path || path.empty?
        path
      end

      def media_manager_iso
        (m = @vm.driver.execute('list', 'dvds').match(/^.+:\s+(?<path>.*VBoxGuestAdditions.iso)$/i)) && m[:path]
      end

      def guess_iso
        path_platform = if Vagrant::Util::Platform.linux?
          "/usr/share/virtualbox/VBoxGuestAdditions.iso"
        elsif Vagrant::Util::Platform.darwin?
          "/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso"
        elsif Vagrant::Util::Platform.windows?
          File.join((ENV["PROGRAM_FILES"] || ENV["PROGRAMFILES"]), "/Oracle/VirtualBox/VBoxGuestAdditions.iso")
        end
        File.exists?(path_platform) ? path_platform : nil
      end

      def web_iso
        "http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso" unless @options[:no_remote]
      end

  end

  class KernelModuleDetector

    def initialize(vm, options = nil)
      @vm = vm
      @options ||= options
    end

    def loaded?
      @vm.channel.test(kernel_module_loaded_command, :sudo => true)
    end

    private

      def kernel_module_loaded_command
        platform = @vm.guest.distro_dispatch
        case platform
        when :debian, :ubuntu, :gentoo, :redhat, :suse, :arch, :linux
          'lsmod | grep vboxsf'
        # :TODO: 
        #   we do not yet know how to rebuild on freebsd and solaris
        #   so it does not make a lot sense to detect them
        # when :freebsd
        #   'kldstat | grep vboxguest'
        # when :solaris
        #   '/usr/sbin/modinfo | grep "vboxguest "'
        else
          @vm.ui.error(I18n.t("vagrant.plugins.vbguest.no_kernel_module_checkup_for_platform", :platform => platform.to_s))
          nil
        end
      end
  end
end