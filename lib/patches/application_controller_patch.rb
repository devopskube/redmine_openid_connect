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
      return require_login_without_openid_connect unless OicSession.plugin_config[:enabled]

      unless User.current.logged?
        if session[:oic_session_id].blank?
          oic_session = create_oic_session
          redirect_to oic_session.authorization_url
          return false
        end

        oic_session = OicSession.find session[:oic_session_id]
        if oic_session.blank?
          oic_session = create_oic_session
          redirect_to oic_session.authorization_url
          return false
        end

        if oic_session.expires_at < DateTime.now
          oic_session.destroy
          oic_session = create_oic_session
          redirect_to oic_session.authorization_url
          return false
        end

        return true
      end

      return false
    end

    def create_oic_session
      oic_session = OicSession.create
      session[:oic_session_id] = oic_session.id
      return oic_session
    end

    # set the current user _without_ resetting the session first
    def logged_user_with_openid_connect=(user)
      if user && user.is_a?(User)
        User.current = user
        start_user_session(user)
      else
        User.current = User.anonymous
      end
    end
  end # InstanceMethods
end
