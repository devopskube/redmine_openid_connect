require 'redmine'
require 'openid_connect'
require 'patches/application_controller_patch'
require 'patches/account_controller_patch'

Redmine::Plugin.register :redmine_openid_connect do
  name 'Redmine Openid Connect plugin'
  author 'Alfonso Juan Dillera'
  description 'OpenID Connect implementation for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  settings :default => { 'empty' => true }, partial: 'settings/redmine_openid_connect_settings'
end

Rails.configuration.to_prepare do
  ApplicationController.send(:include, OpenidConnect::ApplicationControllerPatch)
  AccountController.send(:include, OpenidConnect::AccountControllerPatch)
end

ActionDispatch::Callbacks.before do
  OpenidConnect.get_current_configuration
end
