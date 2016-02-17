module RedmineOpenidConnect
  module AccountControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        # Add before filters and stuff here
        alias_method_chain :logout, :openid_connect
        alias_method_chain :invalid_credentials, :openid_connect
      end
    end
  end # AccountControllerPatch

  module InstanceMethods
    def logout_with_openid_connect
      return logout_without_openid_connect unless OicSession.plugin_config[:enabled]

      oic_session = OicSession.find(session[:oic_session_id])
      oic_session.destroy
      logout_user
      reset_session
      redirect_to oic_session.end_session_url
    end

    def oic_reauthorize
      oic_session = OicSession.find(session[:oic_session_id])
      oic_session.destroy
      logout_user
      reset_session
      require_login
    end

    def oic
      if params[:code]
        oic_session = OicSession.find(session[:oic_session_id])

        unless oic_session.present?
          return invalid_credentials
        end

        # verify request state or reauthorize
        return oic_reauthorize unless oic_session.state == params[:state]

        oic_session.update_attributes!(authorize_params)

        # verify id token nonce or reauthorize
        return oic_reauthorize unless oic_session.nonce == oic_session.claims['nonce']

        # get access token and user info
        oic_session.get_access_token!
        user_info = oic_session.get_user_info!

        # verify application authorization
        unless oic_session.is_authorized?
          return invalid_credentials
        end

        # Check if there's already an existing user
        user = User.find_by_mail(user_info["email"])

        if user.nil?
          user = User.new

          user.login = user_info["user_name"]

          user.assign_attributes({
            firstname: user_info["given_name"],
            lastname: user_info["family_name"],
            mail: user_info["email"],
            mail_notification: 'only_my_events',
            last_login_on: Time.now
          })

          if user.save
            oic_session.user_id = user.id
            oic_session.save!
            successful_authentication(user)
          else
            flash.now[:warning] ||= "Unable to create user #{user.login}: "
            user.errors.full_messages.each do |error|
              logger.warn "Unable to create user #{user.login} due to #{error}"
              flash.now[:warning] += "#{error}. "
            end
            return invalid_credentials
          end
        else
          oic_session.user_id = user.id
          oic_session.save!
          successful_authentication(user)
        end # if user.nil?
      end
    end

    def invalid_credentials_with_openid_connect
      return invalid_credentials_without_openid_connect unless OicSession.plugin_config[:enabled]
      logger.warn "Failed login for '#{params[:username]}' from #{request.remote_ip} at #{Time.now.utc}"
      flash.now[:error] = (l(:notice_account_invalid_creditentials) + ". " + "<a href='#{signout_path}'>Try a different account</a>").html_safe
    end

    def rpiframe
      @oic_session = OicSession.find(session[:oic_session_id])
      render layout: false
    end

    def authorize_params
      # compatible with both rails 3 and 4
      if params.respond_to?(:permit)
        params.permit(
          :code,
          :id_token,
          :session_state,
        )
      else
        params.select do |k,v|
          [
            'code',
            'id_token',
            'session_state',
          ].include?(k)
        end
      end
    end
  end # InstanceMethods
end
