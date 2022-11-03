require 'redmine'
require_relative 'lib/redmine_openid_connect/application_controller_patch'
require_relative 'lib/redmine_openid_connect/account_controller_patch'
require_relative 'lib/redmine_openid_connect/hooks'

loader = RedminePluginKit::Loader.new plugin_id: 'redmine_openid_connect'

Redmine::Plugin.register :redmine_openid_connect do
  name 'Redmine Openid Connect plugin'
  author 'Alfonso Juan Dillera / Markus M. May'
  description 'OpenID Connect implementation for Redmine'
  version '0.9.5'
  url 'https://github.com/devopskube/redmine_openid_connect'
  author_url 'http://github.com/adillera'

  settings :default => { 'empty' => true }, partial: 'settings/redmine_openid_connect_settings'
end

RedminePluginKit::Loader.persisting { loader.load_model_hooks! }
RedminePluginKit::Loader.to_prepare { 
    ApplicationController.prepend(RedmineOpenidConnect::ApplicationControllerPatch)
    AccountController.prepend(RedmineOpenidConnect::AccountControllerPatch)
    } if Rails.version < '6.0'