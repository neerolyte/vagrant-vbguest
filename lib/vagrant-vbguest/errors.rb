module VagrantVbguest

  module Errors

    class VbguestError < Vagrant::Errors::VagrantError
      def error_namespace; "vagrant.plugins.vbguest.errors"; end
    end
    
    class IsoPathAutodetectionError < VbguestError
      error_key :autodetect_iso_path
    end

    class DownloadingDisabledError < VbguestError
      error_key :downloading_disabled
    end

  end
end