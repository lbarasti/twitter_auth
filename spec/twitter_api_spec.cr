require "./spec_helper"

describe TwitterAPI do

  # request fixtures
  consumer_key = "consumer:k3y"
  consumer_secret = "consumer:s3cret"
  whitelisted_callback_url = "localhost:3000"
  oauth_verifier = "oauth:v3rifier"
  # response fixtures
  oauth_token = "oauth:tok3n"
  oauth_token_secret = "oauth:token:s3cret"
  oauth_token_access = "acc3ss:token"
  oauth_token_secret_access = "acc3ss:secret"
  access_token = TwitterAPI::TokenResponse.new(oauth_token_access, oauth_token_secret_access)
  user_id = "38895958"

  post = ->(callback_url : String) {
    ->(method : Symbol, url : String,
              headers : Hash(String, String), params : Hash(String, String)) {
      auth_header = headers["Authorization"]
      auth_header.should match(/^OAuth /)
      case url
      when "https://api.twitter.com/oauth/request_token"
        # Step 1 of https://developer.twitter.com/en/docs/basics/authentication/overview/3-legged-oauth.html
        auth_header.should contain(
          "oauth_callback=\"#{TwitterAuth.escape(callback_url)}\"")
        auth_header.should contain(
          "oauth_consumer_key=\"#{TwitterAuth.escape(consumer_key)}\"")

        "oauth_token=#{oauth_token}&" \
        "oauth_token_secret=#{oauth_token_secret}&" \
        "oauth_callback_confirmed=#{callback_url==whitelisted_callback_url}"
      when "https://api.twitter.com//oauth/access_token"
        # Step 3 of https://developer.twitter.com/en/docs/basics/authentication/overview/3-legged-oauth.html
        auth_header.should contain(
          "oauth_token=\"#{TwitterAuth.escape(oauth_token)}\"")
        auth_header.should contain(
          "oauth_verifier=\"#{TwitterAuth.escape(oauth_verifier)}\"")
        auth_header.should contain(
          "oauth_consumer_key=\"#{TwitterAuth.escape(consumer_key)}\"")

        "oauth_token=#{oauth_token_access}&" \
        "oauth_token_secret=#{oauth_token_secret_access}"
      when "https://api.twitter.com/1.1/account/verify_credentials.json"
        # See https://developer.twitter.com/en/docs/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials
        auth_header.should contain(
          "oauth_token=\"#{TwitterAuth.escape(oauth_token_access)}\"")
        "{\"id\": #{user_id},\"id_str\": \"#{user_id}\"}"
      when "https://api.twitter.com/1.1/oauth/invalidate_token"
        # See https://developer.twitter.com/en/docs/basics/authentication/api-reference/invalidate_access_token
        auth_header.should contain(
          "oauth_token=\"#{TwitterAuth.escape(oauth_token_access)}\"")
        "{\"access_token\":\"#{oauth_token_access}\"}"
      else
        raise Exception.new("Unexpected Twitter URL")
      end
    }
  }

  api = TwitterAPI.new(consumer_key, consumer_secret, whitelisted_callback_url, post.call(whitelisted_callback_url))
  api_unverified_callback_url = TwitterAPI.new(consumer_key, consumer_secret, "https://other.url", post.call("https://other.url"))

  describe "#get_token" do
    it "generates a request token + secret" do
      api.get_token.should eq(
        TwitterAPI::TokenResponse.new(oauth_token, oauth_token_secret))
    end
    it "throws an error if the callback is not verified" do
      expect_raises(TwitterAPI::CallbackNotConfirmed) do
        api_unverified_callback_url.get_token
      end
    end
  end
  describe "#upgrade_token" do
    it "converts a request token into an access one" do
      api.upgrade_token(oauth_token, oauth_verifier).should eq(access_token)
    end
  end
  describe "#verify" do
    it "returns a representation of the requesting user" do
      api.verify(access_token).should contain(user_id)
    end
  end
  describe "#invalidate_token" do
    it "returns the token itself, if a valid token is passed" do
      api.invalidate_token(access_token).should contain(oauth_token_access)
    end
  end
  describe "TwitterAPI.authenticate_url" do
    it "returns the /authenticate URL with the given token as query string parameter" do
      url = TwitterAPI.authenticate_url("my-token")
      url.should eq "https://api.twitter.com/oauth/authenticate?oauth_token=my-token"
    end
  end
end
