require 'net/http'
require  'base64'

module OpenidConnect
  extend self

  def enabled?
    setting(:enabled)
  end

  def authorization_uri
    authorization_endpoint + authorize_query_string
  end

  def get_current_configuration
    return nil unless enabled?
    host = setting(:openid_connect_server_url)
    return nil unless host
    configuration = '/.well-known/openid-configuration'

    uri = URI(host + configuration)

    @current_configuration ||= HTTParty.get(uri)
  end

  def store_auth_values(data)
    @session_id = data[:session_id]
    @scope = data[:scope]
    @code = data[:code]
    @id_token = data[:id_token]

    get_authorization_token
  end

  def get_authorization_token
    host = openid_config(:token_endpoint)
    uri = URI(host)

    response = HTTParty.post(
      uri,
      body: authorization_token_query_string
    ).with_indifferent_access

    @access_token = response[:access_token]
    @token_type = response[:token_type]
    @expires_in = response[:expires_in]
    @refresh_token = response[:refresh_token]
  end

  def get_user_info
    host = openid_config(:userinfo_endpoint)
    uri = URI(host)

    HTTParty.post(uri, body: { access_token: access_token })
  end

  def logout_session_uri
    openid_config(:end_session_endpoint) + logout_session_query_string
  end

  private
  def setting(name)
    Setting.plugin_redmine_openid_connect[name]
  end

  def openid_config(name)
    @current_configuration[name]
  end

  def access_token
    @access_token
  end

  def token_type
    @token_type
  end

  def expires_in
    @expires_in
  end

  def refresh_token
    @refresh_token
  end

  def session_id
    @session_id
  end

  def scope
    @scope
  end

  def code
    @code
  end

  def id_token
    @id_token
  end

  def authorization_endpoint
    @current_configuration[:authorization_endpoint]
  end

  def host_name
    Setting.find_by_name('host_name').value
  end

  def redirect_uri
    "#{ host_name }/oic"
  end

  def authorize_query_string
    openid_state = SecureRandom.uuid
    openid_nonce = SecureRandom.uuid
    session[:openid_state] = openid_state
    session[:openid_nonce] = openid_nonce
    query_string = ['response_type=code+id_token',
                    "state=#{openid_state}",
                    "nonce=#{openid_nonce}",
                    'scope=openid+profile+email+user_name',
                    "redirect_uri=#{ redirect_uri }",
                    "client_id=#{ setting(:client_id) }"]

    "?#{ query_string.join('&') }"
  end

  def authorization_token_query_string
    {
      'grant_type' => 'authorization_code',
      'code' => code,
      'scope' => scope,
      'id_token' => id_token,
      'redirect_uri' => redirect_uri,
      'client_id' => setting(:client_id),
    }
  end

  def logout_session_query_string
    query_string = [
      "id_token_hint=#{ id_token }",
      "session_id=#{ session_id }",
      "post_logout_redirect_uri=#{ host_name }"
    ]

    "?#{ query_string.join('&') }"
  end
end
