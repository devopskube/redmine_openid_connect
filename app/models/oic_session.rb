class OicSession < ActiveRecord::Base
  unloadable

  before_create :randomize_state!
  before_create :randomize_nonce!

  def self.client_config
    Setting.plugin_redmine_openid_connect
  end

  def client_config
    self.class.client_config
  end

  def self.host_name
    Setting.protocol + "://" + Setting.host_name
  end

  def host_name
    self.class.host_name
  end

  def self.enabled?
    client_config[:enabled]
  end

  def self.disabled?
    !self.enabled?
  end

  def self.openid_configuration_url
    client_config[:openid_connect_server_url] + '/.well-known/openid-configuration'
  end

  def self.get_dynamic_config
    hash = Digest::SHA1.hexdigest client_config.to_json
    expiry = client_config[:dynamic_config_expiry] || 86400
    Rails.cache.fetch("oic_session_dynamic_#{hash}", expires_in: expiry) do
      HTTParty::Basement.default_options.update(verify: false) if client_config[:disable_ssl_validation]
      ActiveSupport::HashWithIndifferentAccess.new HTTParty.get(openid_configuration_url)
    end
  end

  def self.dynamic_config
    @dynamic_config ||= get_dynamic_config
  end

  def dynamic_config
    self.class.dynamic_config
  end

  def self.get_token(query)
    uri = dynamic_config['token_endpoint']

    HTTParty::Basement.default_options.update(verify: false) if client_config[:disable_ssl_validation]
    response = HTTParty.post(
      uri,
      body: query,
      basic_auth: {username: client_config[:client_id], password: client_config[:client_secret] }
    )
  end

  def get_access_token!
    response = self.class.get_token(access_token_query)
    if response["error"].blank?
      self.access_token = response["access_token"] if response["access_token"].present?
      self.refresh_token = response["refresh_token"] if response["refresh_token"].present?
      self.id_token = response["id_token"] if response["id_token"].present?
      self.expires_at = (DateTime.now + response["expires_in"].seconds) if response["expires_in"].present?
      self.save!
    end
    return response
  end

  def refresh_access_token!
    response = self.class.get_token(refresh_token_query)
    if response["error"].blank?
      self.access_token = response["access_token"] if response["access_token"].present?
      self.refresh_token = response["refresh_token"] if response["refresh_token"].present?
      self.id_token = response["id_token"] if response["id_token"].present?
      self.expires_at = (DateTime.now + response["expires_in"].seconds) if response["expires_in"].present?
      self.save!
    end
    return response
  end

  def self.parse_token(token)
    jwt = token.split('.')
    return JSON::parse(Base64::decode64(jwt[1]))
  end

  def claims
    if @claims.blank? || id_token_changed?
      @claims = self.class.parse_token(id_token)
    end
    return @claims
  end

  def get_user_info!
    uri = dynamic_config['userinfo_endpoint']

    HTTParty::Basement.default_options.update(verify: false) if client_config[:disable_ssl_validation]
    response = HTTParty.get(
      uri,
      headers: { "Authorization" => "Bearer #{access_token}" }
    )

    if response.headers["content-type"] == 'application/jwt'
      # signed / encrypted response, extract before using
      return self.class.parse_token(response)
    else
      # unsigned response, just return the bare json
      return JSON::parse(response.body)
      decoded_token = response.body
    end
  end

  def authorized?
    if client_config[:group].blank?
      return true
    end

    return false if !user["member_of"]

    return true if self.admin?

    if client_config[:group].present? &&
       user["member_of"].include?(client_config[:group])
      return true
    end

    return false
  end

  def admin?
    if client_config[:admin_group].present? &&
       user["member_of"].include?(client_config[:admin_group])
      return true
    end

    return false
  end

  def user
    if @user.blank? || id_token_changed?
      @user = JSON::parse(Base64::decode64(id_token.split('.')[1]))
    end
    return @user
  end

  def authorization_url
    config = dynamic_config
    config["authorization_endpoint"] + "?" + authorization_query.to_param
  end

  def end_session_url
    config = dynamic_config
    config["end_session_endpoint"] + "?" + end_session_query.to_param
  end

  def randomize_state!
    self.state = SecureRandom.uuid unless self.state.present?
  end

  def randomize_nonce!
    self.nonce = SecureRandom.uuid unless self.nonce.present?
  end

  def authorization_query
    query = {
      "response_type" => "code",
      "state" => self.state,
      "nonce" => self.nonce,
      "scope" => "openid profile email user_name",
      "redirect_uri" => "#{host_name}/oic/local_login",
      "client_id" => client_config[:client_id],
    }
  end

  def access_token_query
    query = {
      'grant_type' => 'authorization_code',
      'code' => code,
      'scope' => 'openid profile email user_name',
      'id_token' => id_token,
      'redirect_uri' => "#{host_name}/oic/local_login",
    }
  end

  def refresh_token_query
    query = {
      'grant_type' => 'refresh_token',
      'refresh_token' => refresh_token,
      'scope' => 'openid profile email user_name',
    }
  end

  def end_session_query
   query = {
     'id_token_hint' => id_token,
     'session_state' => session_state,
     'post_logout_redirect_uri' => "#{host_name}/oic/local_logout",
   }
  end

  def expired?
    self.expires_at < DateTime.now
  end

  def incomplete?
    self.access_token.blank?
  end

  def complete?
    self.access_token.present?
  end
end
