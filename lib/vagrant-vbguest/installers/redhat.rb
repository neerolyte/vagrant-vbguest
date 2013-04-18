module VagrantVbguest
  module Installers
    class RedHat < Linux
      include VagrantVbguest::Helpers::Rebootable

      # Scientific Linux (and probably CentOS) both show up as :redhat
      # fortunately they're probably both similar enough to RHEL
      # (RedHat Enterprise Linux) not to matter.
      def self.match?(vm)
        :redhat == self.distro(vm)
      end

      def install(opts=nil, &block)
        # do simple deps first
        install_deps(opts, &block)
        check_and_upgrade_kernel_devel(opts, &block)
        # yield to regular tools installation
        super
      end

    protected
      def install_deps(opts=nil, &block)
        communicate.sudo(install_dependencies_cmd, opts, &block)
      end

      def check_and_upgrade_kernel_devel(opts=nil, &block)
        check_opts = {:error_check => false}.merge(opts || {})
        exit_status = communicate.sudo("rpm -q kernel-devel-`uname -r`", check_opts, &block) 

        if exit_status == 1 then
          upgrade_kernel(opts, &block)
        end
      end

      def upgrade_kernel(opts=nil, &block)
        @env.ui.warn("Attempting to upgrade the kernel as the right version of kernel-devel is missing from yum repos")
        communicate.sudo("yum install -y kernel{,-devel}", opts, &block)
        @env.ui.warn("Restarting to activate upgraded kernel so that VirtualBox Guest Tools installation can continue")
        reboot(@vm, {:auto_reboot => true})
      end

      def install_dependencies_cmd
        "yum install -y #{dependencies}"
      end

      def dependencies
        packages = ['kernel-devel-`uname -r`', 'gcc', 'make', 'perl']
        packages.join ' '
      end
    end
  end
end
VagrantVbguest::Installer.register(VagrantVbguest::Installers::RedHat, 5)
