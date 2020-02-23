require "./spec_helper"

describe TwitterAPI do
  f = Fixtures.new
  consumer_key = "consumer:k3y"
  consumer_secret = "consumer:s3cret"
  access_token = TwitterAPI::TokenPair.new(f.oauth_token_access, f.oauth_token_secret_access)

  api = TestTwitterAPI.new(consumer_key, consumer_secret, f.whitelisted_callback_url)
  api_unverified_callback_url = TestTwitterAPI.new(consumer_key, consumer_secret, "https://other.url")

  describe "#upgrade_token" do
    it "converts a request token into an access one" do
      api.upgrade_token(f.oauth_token, f.oauth_verifier).should eq(access_token)
    end
  end
  describe "#verify" do
    it "returns a representation of the requesting user" do
      api.verify(access_token).should contain(f.user_id)
    end
  end
  describe "#invalidate_token" do
    it "returns the token itself, if a valid token is passed" do
      api.invalidate_token(access_token).should contain(f.oauth_token_access)
    end
  end
end
