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
      if params[:id_token]
        OpenidConnect.store_auth_values(params)

        data = OpenidConnect.get_user_info
        unless OpenidConnect.is_authorized? data
          return invalid_credentials
        end

        # Check if there's already an existing user
        user = User.find_by_mail(data["email"])

        if user.nil?
          user = User.new

          user.login = data["user_name"]

          user.assign_attributes({
            firstname: data["given_name"],
            lastname: data["family_name"],
            mail: data["email"],
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
