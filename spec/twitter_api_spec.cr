require "./spec_helper"

F = Fixtures.new

describe TwitterAPI do
  consumer_key = "consumer:k3y"
  consumer_secret = "consumer:s3cret"
  access_token = TwitterAPI::TokenPair.new(F.oauth_token_access, F.oauth_token_secret_access)

  api = TestTwitterAPI.new(consumer_key, consumer_secret, F.whitelisted_callback_url)
  api_unverified_callback_url = TestTwitterAPI.new(consumer_key, consumer_secret, "https://other.url")

  describe "#get_token" do
    it "generates a request token + secret" do
      api.get_token.should eq(
        TwitterAPI::TokenPair.new(F.oauth_token, F.oauth_token_secret))
    end
    it "throws an error if the callback is not verified" do
      expect_raises(TwitterAPI::CallbackNotConfirmed) do
        api_unverified_callback_url.get_token
      end
    end
  end
  describe "#upgrade_token" do
    it "converts a request token into an access one" do
      api.upgrade_token(F.oauth_token, F.oauth_verifier).should eq(access_token)
    end
  end
  describe "#verify" do
    it "returns a representation of the requesting user" do
      api.verify(access_token).should contain(F.user_id)
    end
  end
  describe "#invalidate_token" do
    it "returns the token itself, if a valid token is passed" do
      api.invalidate_token(access_token).should contain(F.oauth_token_access)
    end
  end
  describe "TwitterAPI.authenticate_url" do
    it "returns the /authenticate URL with the given token as query string parameter" do
      url = TwitterAPI.authenticate_url("my-token")
      url.should eq "https://api.twitter.com/oauth/authenticate?oauth_token=my-token"
    end
  end
end
