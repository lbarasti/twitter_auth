require "spec"
require "../src/twitter_auth"

module FixturesModule
  # request fixtures
  getter whitelisted_callback_url = "localhost:3000",
    oauth_verifier = "oauth:v3rifier"
  # response fixtures
  getter oauth_token = "oauth:tok3n",
    oauth_token_secret = "oauth:token:s3cret",
    oauth_token_access = "acc3ss:token",
    oauth_token_secret_access = "acc3ss:secret",
    user_id = "38895958",
    token_pair = TwitterAPI::TokenPair.new("oauth:tok3n", "acc3ss:secret")
end

class Fixtures
  include FixturesModule
end

# TwitterAPI with stubbed HTTP responses
class TestTwitterAPI < TwitterAPI
  include FixturesModule

  def exec(method : Symbol, url : String, headers : Hash(String, String), params : Hash(String, String))
    auth_header = headers["Authorization"]
    auth_header.should match(/^OAuth /)
    case url
    when "https://api.twitter.com/oauth/request_token"
      # Step 1 of https://developer.twitter.com/en/docs/basics/authentication/overview/3-legged-oauth.html
      auth_header.should contain(
        "oauth_callback=\"#{SimpleOAuth.escape(@callback_url)}\"")
      auth_header.should contain(
        "oauth_consumer_key=\"#{SimpleOAuth.escape(@consumer_key)}\"")

      "oauth_token=#{oauth_token}&" \
      "oauth_token_secret=#{oauth_token_secret}&" \
      "oauth_callback_confirmed=#{@callback_url==whitelisted_callback_url}"
    when "https://api.twitter.com/oauth/access_token"
      # Step 3 of https://developer.twitter.com/en/docs/basics/authentication/overview/3-legged-oauth.html
      auth_header.should contain(
        "oauth_token=\"#{SimpleOAuth.escape(oauth_token)}\"")
      auth_header.should contain(
        "oauth_verifier=\"#{SimpleOAuth.escape(oauth_verifier)}\"")
      auth_header.should contain(
        "oauth_consumer_key=\"#{SimpleOAuth.escape(@consumer_key)}\"")
      params["oauth_verifier"].should eq oauth_verifier

      "oauth_token=#{oauth_token_access}&" \
      "oauth_token_secret=#{oauth_token_secret_access}"
    when "https://api.twitter.com/1.1/account/verify_credentials.json"
      # See https://developer.twitter.com/en/docs/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials
      auth_header.should contain(
        "oauth_token=\"#{SimpleOAuth.escape(oauth_token_access)}\"")
      "{\"id\": #{user_id},\"id_str\": \"#{user_id}\"}"
    when "https://api.twitter.com/1.1/oauth/invalidate_token"
      # See https://developer.twitter.com/en/docs/basics/authentication/api-reference/invalidate_access_token
      auth_header.should contain(
        "oauth_token=\"#{SimpleOAuth.escape(oauth_token_access)}\"")
      "{\"access_token\":\"#{oauth_token_access}\"}"
    else
      raise Exception.new("Unexpected Twitter URL")
    end
  end
end