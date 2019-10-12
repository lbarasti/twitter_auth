require "./twitter_auth"
require "dataclass"

class TwitterAPI
  @@oauth_version = "1.0"
  @@request_token_url = "https://api.twitter.com/oauth/request_token"
  @@access_token_url = "https://api.twitter.com//oauth/access_token"
  @@verify_credentials_url = "https://api.twitter.com/1.1/account/verify_credentials.json"

  def initialize(@consumer_key : String, @consumer_secret : String,
    @callback_url : String, @post : Proc(Symbol, String, Hash(String, String), Hash(String, String), String))
    @t_auth = TwitterAuth.new(@consumer_secret)
  end

  def get_token : TokenResponse
    auth_params = {
      "oauth_callback" => @callback_url
    }

    body = @post.call(:post, @@request_token_url,
      {"Authorization" => self.auth_header("post", @@request_token_url, auth_params)}, {} of String => String)

    TwitterAPI.parse_token_response(body)
  end

  def upgrade_token(token : String, verifier : String) : TokenResponse
    auth_params = {
      "oauth_token" => token,
      "oauth_verifier" => verifier
    }

    body = @post.call(:post, @@access_token_url,
      {"Authorization" => self.auth_header("post", @@access_token_url, auth_params)}, {"oauth_verifier" => verifier})

    TwitterAPI.parse_token_response(body)
  end

  def verify(token : TokenResponse)
    user_auth = TwitterAuth.new(@consumer_secret, token.oauth_token_secret)

    auth_params = {
      "oauth_token" => token.oauth_token
    }

    @post.call(:get, @@verify_credentials_url,
      {"Authorization" => self.auth_header("get", @@verify_credentials_url, auth_params, user_auth)}, {} of String => String)
  end

  def auth_header(method : String, url : String, auth_params : Hash(String, String), auth = @t_auth) : String
    nonce = TwitterAuth.nonce()
    timestamp = Time::Format.new("%s").format(Time.now)
    auth_params.merge!({
      "oauth_consumer_key" => @consumer_key,
      "oauth_nonce" => nonce,
      "oauth_signature_method" => TwitterAuth.signature_method,
      "oauth_timestamp" => timestamp,
      "oauth_version" => @@oauth_version
    })

    oauth_signature = auth.signature(method, url, auth_params)

    auth_params["oauth_signature"] = oauth_signature

    "OAuth #{auth_params.map{ |k,v| "#{k}=\"#{URI.escape(v)}\"" }.join(", ")}"
  end

  def self.parse_token_response(res) : TokenResponse
    res_body = res.split("&").map(&.split("=")).to_h

    TokenResponse.from_response_body(res_body)
  end

  
  dataclass TokenResponse{oauth_token : String, oauth_token_secret : String}
  
  class TokenResponse
    def self.from_response_body(res_body : Hash(String, String)) : TokenResponse
      if ["true", nil].includes?(res_body["oauth_callback_confirmed"]?)
        TokenResponse.new(res_body["oauth_token"], res_body["oauth_token_secret"])
      else
        raise CallbackNotConfirmed.new
      end
    end
  end

  class CallbackNotConfirmed < Exception
  end
end
