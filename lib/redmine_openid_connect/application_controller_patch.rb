module RedmineOpenidConnect
  module ApplicationControllerPatch
    def require_login
      return super unless OicSession.enabled?

      if !User.current.logged?
        if request.get?
          url = request.original_url
        else
          url = url_for(:controller => params[:controller], :action => params[:action], :id => params[:id], :project_id => params[:project_id])
        end
        session[:remember_url] = url
        redirect_to oic_login_url
        return false
      end
    end

    # set the current user _without_ resetting the session first
    def logged_user=(user)
      return super(user) unless OicSession.enabled?

      if user && user.is_a?(User)
        User.current = user
        start_user_session(user)
      else
        User.current = User.anonymous
      end
    end
  end # ApplicationControllerPatch
end
