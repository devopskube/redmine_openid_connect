module RedmineOpenidConnect
  module ApplicationControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :require_login, :openid_connect
        alias_method_chain :logged_user=, :openid_connect
      end
    end
  end # ApplicationControllerPatch

  module InstanceMethods
    def require_login_with_openid_connect
      return require_login_without_openid_connect unless OicSession.enabled?

      unless User.current.logged?
        redirect_to oic_login_url
        return false
      end

      return true
    end

    # set the current user _without_ resetting the session first
    def logged_user_with_openid_connect=(user)
      return logged_user_without_openid_connect=(user) unless OicSession.enabled?

      if user && user.is_a?(User)
        User.current = user
        start_user_session(user)
      else
        User.current = User.anonymous
      end
    end
  end # InstanceMethods
end
