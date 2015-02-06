class OpenIdConnectController < ApplicationController
  unloadable

  def has_authorization
    if params[:id_token]
      OpenidConnect.store_auth_values(params)

      OpenidConnect.get_authorization_token

      redirect_to create_or_login_the_account_path
    end
  end
end
