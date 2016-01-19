require 'redmine'
require 'openid_connect'
require 'patches/application_controller_patch'
require 'patches/account_controller_patch'

Redmine::Plugin.register :redmine_openid_connect do
  name 'Redmine Openid Connect plugin'
  author 'Alfonso Juan Dillera'
  description 'OpenID Connect implementation for Redmine'
  version '0.0.2'
  url 'http://bitbucket.org/intelimina/redmine_openid_connect'
  author_url 'http://github.com/adillera'

  settings :default => { 'empty' => true }, partial: 'settings/redmine_openid_connect_settings'
end

Rails.configuration.to_prepare do
  ApplicationController.send(:include, OpenidConnect::ApplicationControllerPatch)
  AccountController.send(:include, OpenidConnect::AccountControllerPatch)
end

ActionDispatch::Callbacks.before do
  OpenidConnect.get_current_configuration
end
