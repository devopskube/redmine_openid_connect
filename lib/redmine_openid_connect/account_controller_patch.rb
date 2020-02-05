module RedmineOpenidConnect
  module AccountControllerPatch

    def login
      if OicSession.disabled? || params[:local_login].present? || request.post?
        return super
      end

      redirect_to oic_login_url
    end

    def logout
      if OicSession.disabled? || params[:local_login].present?
        return super
      end

      oic_session = OicSession.find(session[:oic_session_id])
      oic_session.destroy
      logout_user
      reset_session
      redirect_to oic_session.end_session_url if oic_session.end_session_url
    rescue ActiveRecord::RecordNotFound => e
      redirect_to oic_local_logout_url
    end

    # performs redirect to SSO server
    def oic_login
      if session[:oic_session_id].blank?
        oic_session = OicSession.create
        session[:oic_session_id] = oic_session.id
      else
        begin
          oic_session = OicSession.find session[:oic_session_id]
        rescue ActiveRecord::RecordNotFound => e
          oic_session = OicSession.create
          session[:oic_session_id] = oic_session.id
        end

        if oic_session.complete? && oic_session.expired?
          response = oic_session.refresh_access_token!
          if response[:error].present?
            oic_session.destroy
            oic_session = OicSession.create
            session[:oic_session_id] = oic_session.id
          end
        end
      end

      redirect_to oic_session.authorization_url
    end

    def oic_local_logout
      logout_user
      reset_session
    end

    def oic_local_login
      if params[:code]
        oic_session = OicSession.find(session[:oic_session_id])

        unless oic_session.present?
          return invalid_credentials
        end

        # verify request state or reauthorize
        unless oic_session.state == params[:state]
          flash[:error] = "Invalid OpenID Connect request."
          return redirect_to oic_local_logout
        end

        oic_session.update_attributes!(authorize_params)

        # verify id token nonce or reauthorize
        if oic_session.id_token.present?
          unless oic_session.claims['nonce'] == oic_session.nonce
            flash[:error] = "ID Token invalid."
            return redirect_to oic_local_logout
          end
        end

        # get access token and user info
        oic_session.get_access_token!
        user_info = oic_session.get_user_info!

        # verify application authorization
        unless oic_session.authorized?
          return invalid_credentials
        end

        username = user_info["user_name"] || user_info["nickname"] || user_info["preferred_username"] || user_info["username"]

        # Check if there's already an existing user
        user = User.find_by_login(username)

        firstname = user_info["given_name"]
        lastname = user_info["family_name"]

        if (firstname.nil? || lastname.nil?) && user_info["name"]
          parts = user_info["name"].split
          if parts.length >= 2
            firstname = parts[0]
            lastname = parts[-1]
          end
        end

        if user.nil?
          user = User.new

          user.login = username

          attributes = {
            firstname: firstname || "",
            lastname: lastname || "",
            mail: user_info["email"],
            mail_notification: 'only_my_events',
            last_login_on: Time.now
          }

          user.assign_attributes attributes

          if user.save
            user.update_attribute(:admin, oic_session.admin?)

            update_groups(user,user_info['groups'])

            oic_session.user_id = user.id
            oic_session.save!
            # after user creation just show "My Page" don't redirect to remember
            successful_authentication(user)
          else
            flash.now[:warning] ||= "Cannot create user #{user.login}: "
            user.errors.full_messages.each do |error|
              logger.warn "Cannot create user #{user.login}, error #{error}"
              flash.now[:warning] += "#{error}. "
            end
            return invalid_credentials
          end
        else
          user.update_attribute(:admin, oic_session.admin?)

          if Setting.plugin_redmine_openid_connect['override_user_attributes']
            user.update_attribute(:firstname, firstname)
            user.update_attribute(:lastname, lastname)
            user.update_attribute(:mail, user_info["email"])
          end

          update_groups(user,user_info['groups'])

          oic_session.user_id = user.id
          oic_session.save!
          # redirect back to initial URL
          if session[:remember_url]
            params[:back_url] = session[:remember_url]
            session[:remember_url] = nil
          end
          successful_authentication(user)
        end # if user.nil?
      end
    end

    def invalid_credentials
      return super unless OicSession.enabled?

      logger.warn "Connection failed for '#{params[:username]}' from #{request.remote_ip} at #{Time.now.utc}"
      flash.now[:error] = (l(:notice_account_invalid_creditentials) + ". " + "<a href='#{signout_path}'>Try with another username</a>").html_safe
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

    def update_groups(user, groups)
      groups.each do |group|
        begin
          rm_g = Group.find_by(:lastname => group.to_s.downcase)
          if rm_g
            logger.error("group found")
            if not rm_g.users.include?(user)
              rm_g.users << user
              logger.error("user added to group")
            end
          else
            logger.error("no group " + group)
            g = Group.new()
            g.name = group
            g.user_ids = [user.id]
            if g.save()
              logger.error("group added")
            end
          end
        rescue ActiveRecord::RecordNotFound
          logger.error("no group " + group)
          g = Group.new()
          g.name = group
          g.user_ids = [user.id]
          if g.save()
            logger.error("group added")
          end
        rescue => e
          logger.error(e)
        end
      end
    end
  end # AccountControllerPatch
end
