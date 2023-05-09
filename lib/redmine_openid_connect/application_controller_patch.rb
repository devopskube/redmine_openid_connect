module RedmineOpenidConnect
  module ApplicationControllerPatch
    def require_login
      if !User.current.logged? && OicSession.enabled?
        if request.get?
          url = request.original_url
        else
          url = url_for(:controller => params[:controller], :action => params[:action], :id => params[:id], :project_id => params[:project_id])
        end
        # this should fix infinite redirect
        # because this plugin not reseting session when assigning logged user
        # it should at least reset session when expired so it will not check every time
        # which will cause infinite redirect
        # also clean lingering oic sessio so that back_url still works
        reset_session
        session[:remember_url] = url
      end
      return super unless (OicSession.enabled? && !OicSession.login_selector?)

      if !User.current.logged?
        redirect_to oic_login_url
        return false
      end
      true
    end

    # set the current user _without_ resetting the session first
    def logged_user=(user)
      # only override parent if the request is from ioc user
      return super(user) unless session[:oic_session_id]

      if user && user.is_a?(User)
        User.current = user
        start_user_session(user)
      else
        User.current = User.anonymous
      end
    end
  end # ApplicationControllerPatch
end

