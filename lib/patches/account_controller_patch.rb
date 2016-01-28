module OpenidConnect
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
      return logout_without_openid_connect unless OpenidConnect.enabled?

      logout_user

      redirect_to OpenidConnect.logout_session_uri
    end

    def oic
      if params[:code]
        OpenidConnect.store_auth_values(params)
        raw_id_token = OpenidConnect.get_user_info

        # decode id_token from userinfo endpoint
        # since it's https, there's no need to verify
	parsed_id_token = JSON::parse(Base64::decode64(raw_id_token.split('.')[1]))

        # store openid session in client session
        oic_session = {}
        oic_session['session_id'] = params[:session_id]
        oic_session['id_token'] = raw_id_token
        oic_session['session_state'] = params['session_state']
        session['oic_session'] = oic_session

        unless OpenidConnect.is_authorized? parsed_id_token
          return invalid_credentials
        end

        # Check if there's already an existing user
        user = User.find_by_mail(parsed_id_token["email"])

        if user.nil?
          user = User.new

          user.login = parsed_id_token["user_name"]

          user.assign_attributes({
            firstname: parsed_id_token["given_name"],
            lastname: parsed_id_token["family_name"],
            mail: parsed_id_token["email"],
            mail_notification: 'only_my_events',
            last_login_on: Time.now
          })

          if user.save
            self.logged_user = user

            successful_authentication(user)
          else
            # Add error handling here
          end
        else
          self.logged_user = user

          successful_authentication(user)
        end # if user.nil?
      end
    end

    def invalid_credentials_with_openid_connect
      return invalid_credentials_without_openid_connect unless OpenidConnect.enabled?
      logger.warn "Failed login for '#{params[:username]}' from #{request.remote_ip} at #{Time.now.utc}"
      flash.now[:error] = l(:notice_account_invalid_creditentials) + ". " + "<a href='#{signout_path}'>Try a different account</a>"
    end
  end # InstanceMethods
end
