module OpenidConnect
  module ApplicationControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        skip_before_filter :check_if_login_required, only: [:has_authorization, :has_authorization_token]
        alias_method_chain :require_login, :openid_connect
      end
    end
  end # ApplicationControllerPatch

  module InstanceMethods
    def require_login_with_openid_connect
      return require_login_without_openid_connect unless OpenidConnect.enabled?

      unless User.current.logged?
        redirect_to OpenidConnect.authorization_uri
      end

      return false
    end
  end # InstanceMethods
end
