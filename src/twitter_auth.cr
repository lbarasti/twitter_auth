require "simple_oauth/signature"
require "simple_oauth/consumer"

class TwitterAPI < SimpleOAuth::Consumer
  @@request_token_url = "https://api.twitter.com/oauth/request_token"
  @@authenticate_url = "https://api.twitter.com/oauth/authenticate"
  @@access_token_url = "https://api.twitter.com/oauth/access_token"
  @@verify_credentials_url = "https://api.twitter.com/1.1/account/verify_credentials.json"
  @@invalidate_token_url = "https://api.twitter.com/1.1/oauth/invalidate_token"

  # Returns a representation of the requesting user if authentication was successful;
  # raises an exception if not. Use this method to test if supplied user credentials are valid.
  #
  # See the [Twitter documentation](https://developer.twitter.com/en/docs/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials)
  def verify(token : TokenPair)
    user_auth = SimpleOAuth::Signature.new(@consumer_secret, token.oauth_token_secret)

    auth_params = {
      "oauth_token" => token.oauth_token
    }

    exec_signed(:get, @@verify_credentials_url, auth_params, @@empty_params, auth = user_auth)
  end

  # Revokes an issued OAuth Access Token by presenting its client credentials.
  #
  # Once an OAuth Access Token has been invalidated, new creation attempts will yield a different
  # OAuth Access Token and usage of the invalidated token will no longer be allowed.
  #
  # See the [Twitter API reference](https://developer.twitter.com/en/docs/basics/authentication/api-reference/invalidate_access_token)
  def invalidate_token(token : TokenPair)
    user_auth = SimpleOAuth::Signature.new(@consumer_secret, token.oauth_token_secret)

    auth_params = {
      "oauth_token" => token.oauth_token
    }

    exec_signed(:post, @@invalidate_token_url, auth_params, @@empty_params, auth = user_auth)
  end

  def upgrade_token(token : String, verifier : String) : TokenPair
    upgrade_token(TokenPair.new(token, ""), verifier)
  end
end
