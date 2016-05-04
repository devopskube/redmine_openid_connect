require_relative '../../app/models/oic_session'

module RedmineOpenidConnect
  class Hooks < Redmine::Hook::ViewListener
    def request
      ActionDispatch::Request.new(ENV)
    end
    def session
      request.session
    end

    def view_layouts_base_body_bottom(context={})
      return unless OicSession.enabled?
      oic_session = OicSession.find context[:request].session[:oic_session_id]
      context[:oic_session] = oic_session
      context[:controller].send(:render_to_string, {
        partial: 'hooks/redmine_openid_connect/view_layouts_base_body_bottom',
        locals: context
      })
    rescue ActiveRecord::RecordNotFound => e
    end
  end
end
