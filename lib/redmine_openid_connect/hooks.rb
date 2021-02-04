require_relative '../../app/models/oic_session'

module RedmineOpenidConnect
  class Hooks < Redmine::Hook::ViewListener
    def request
      ActionDispatch::Request.new(ENV)
    end
    def session
      request.session
    end

    def view_account_login_bottom(context={})
      return unless (OicSession.enabled? && OicSession.login_selector?)
      if context[:request].session[:oic_session_id].blank?
        oic_session = OicSession.create
      else
        oic_session = OicSession.find context[:request].session[:oic_session_id]
      end
      context[:oic_session] = oic_session
      context[:controller].send(:render_to_string, {
        partial: 'hooks/redmine_openid_connect/view_account_login_bottom',
        locals: context
      })
    rescue ActiveRecord::RecordNotFound => e
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

    def view_layouts_base_html_head(context={})
      stylesheet_link_tag(:redmine_openid_connect, :plugin => 'redmine_openid_connect')
    end
  end
end
