require "http"
require "oauth"
require "./twitter_auth"

abstract class OAuth1API
  @@oauth_version = "1.0"
  @@empty_params = {} of String => String

  # Creates a new `OAuth1API` with the specified credentials.
  def initialize(@consumer_key : String, @consumer_secret : String, @callback_url : String)
    @app_auth = TwitterAuth.new(@consumer_secret)
    @consumer = OAuth::Consumer.new("", @consumer_key, @consumer_secret,
      request_token_uri: @@request_token_url,
      authorize_uri: @@authenticate_url,
      access_token_uri: @@access_token_url)
  end

  # Allows a Consumer application to obtain an OAuth Request Token to request user authorization.
  #
  # Returns a `TokenPair` representing the OAuth Request Token data.
  def get_token : TokenPair
    # auth_params = {
    #   "oauth_callback" => @callback_url
    # }

    # body = exec_signed(:post, @@request_token_url, auth_params)

    # OAuth1API.parse_token_response(body)
    t = @consumer.get_request_token(@callback_url)
    TokenPair.new(t.token, t.secret)
  end

  # Converts the OAuth Request Token into an OAuth Access Token that can be used to call the API on the users' behalf.
  # This method only uses the consumer secret to sign the request, as opposed to the method's overload accepting a `TokenPair` as an argument.
  # This is the method to use for OAuth providers such as Twitter. 
  #
  # Returns a `TokenPair` representing the OAuth Access Token data.
  def upgrade_token(token : String, verifier : String) : TokenPair
    # auth_params = {
    #   "oauth_token" => token,
    #   "oauth_verifier" => verifier
    # }

    # body = exec_signed(:post, @@access_token_url, auth_params, {"oauth_verifier" => verifier})

    # OAuth1API.parse_token_response(body)
    t = @consumer.get_access_token(OAuth::AccessToken.new(token, ""), verifier)
    TokenPair.new(t.token, t.secret)
  end

  # Converts the OAuth Request Token into an OAuth Access Token that can be used to call the API on the users' behalf.
  # This method uses both the consumer secret and the resource owner secret to sign the request, as opposed to the method's overload accepting a token `String` as an argument.
  # This is the method to use for OAuth providers such as Tumblr. 
  #
  # Returns a `TokenPair` representing the OAuth Access Token data.
  def upgrade_token(token : TokenPair, verifier : String) : TokenPair
    # user_auth = TwitterAuth.new(@consumer_secret, token.oauth_token_secret)
    # auth_params = {
    #   "oauth_token" => token.oauth_token,
    #   "oauth_verifier" => verifier
    # }

    # body = exec_signed(:post, @@access_token_url, auth_params, {"oauth_verifier" => verifier}, auth = user_auth)

    # TumblrAPI.parse_token_response(body)
    t = @consumer.get_access_token(OAuth::AccessToken.new(token.oauth_token, token.oauth_token_secret), verifier)
    TokenPair.new(t.token, t.secret)
  end

  # Returns the `/authenticate` URL with the OAuth Request Token passed as query string parameter.
  # This is used in Step 2 of the 3-legged OAuth flow.
  def self.authenticate_url(request_token : String)
    @@authenticate_url % request_token
  end

  # A struct encapsulating OAuth Token and OAuth Token Secret.
  record TokenPair, oauth_token : String, oauth_token_secret : String do
    def [](idx : Int32)
      [oauth_token, oauth_token_secret][idx]
    end
  end

  # An exception signaling an anomaly in the callback URL.
  class CallbackNotConfirmed < Exception
  end

  # Defines how HTTP requests are issued within the library.
  # 
  # Returns a String representing the body of the response.
  #
  # This method can be overriden to provide a custom HTTP client.
  protected def exec(method : Symbol, url : String, headers : Hash(String, String), query_params : Hash(String, String))
    http_params = HTTP::Params.encode(query_params)
    http_headers = HTTP::Headers.new.tap { |hh| headers.each {|(k,v)| hh[k] = v} }
    uri = URI.parse(url + "?" + http_params)
    method_str = method.to_s.upcase

    HTTP::Client.exec(method_str, uri, http_headers).body
  end

  protected def self.parse_token_response(res) : TokenPair
    res_body = res.split("&").map(&.split("=")).to_h

    if ["true", nil].includes?(res_body["oauth_callback_confirmed"]?)
      TokenPair.new(res_body["oauth_token"], res_body["oauth_token_secret"])
    else
      raise CallbackNotConfirmed.new
    end
  end

  private def exec_signed(method : Symbol, url : String, headers : Hash(String, String),
                          query_params : Hash(String, String) = @@empty_params, auth = @app_auth)
    signed_headers = {"Authorization" => self.auth_header(method.to_s, url, headers, auth)}
    exec(method, url, signed_headers, query_params)
  end

  private def auth_header(method : String, url : String, auth_params : Hash(String, String), auth = @app_auth) : String
    nonce = TwitterAuth.nonce()
    timestamp = Time.utc.to_unix.to_s
    auth_params.merge!({
      "oauth_consumer_key" => @consumer_key,
      "oauth_nonce" => nonce,
      "oauth_signature_method" => TwitterAuth::SignatureMethod,
      "oauth_timestamp" => timestamp,
      "oauth_version" => @@oauth_version
    })

    oauth_signature = auth.signature(method, url, auth_params)

    auth_params["oauth_signature"] = oauth_signature

    "OAuth #{auth_params.map{ |k,v| "#{k}=\"#{TwitterAuth.escape(v)}\"" }.join(", ")}"
  end
end