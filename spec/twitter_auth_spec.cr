require "./spec_helper"

describe TwitterAuth do
  consumer_secret = "kAcSOqF21Fu85e7zjz7ZN2U4ZRhfV3WpwPAoE3Z7kBw"
  token_secret = "LswwdoUaIvS8ltyTt5jkRh4J50vUPVVHtR2YPi5kE"

  base_url = "https://api.twitter.com/1.1/statuses/update.json"
  parameters = {
    "status" =>	"Hello Ladies + Gentlemen, a signed OAuth request!",
    "include_entities" =>	"true",
    "oauth_consumer_key" =>	"xvz1evFS4wEEPTGEFPHBog",
    "oauth_nonce" =>	"kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg",
    "oauth_signature_method" =>	"HMAC-SHA1",
    "oauth_timestamp" =>	"1318622958",
    "oauth_token" =>	"370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb",
    "oauth_version" =>	"1.0"
  }
  parameter_string = "include_entities=true&oauth_consumer_key=xvz1evFS4wEEPTGEFPHBog&oauth_nonce=kYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1318622958&oauth_token=370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb&oauth_version=1.0&status=Hello%20Ladies%20%2B%20Gentlemen%2C%20a%20signed%20OAuth%20request%21"
  expected_signature = "hCtSmYh+iHYCEqBWrE7C7hYmtUk="

  it "encodes the signing key from the consumer secret" do
    TwitterAuth.new("a=s3cret/!")
      .signing_key
      .should eq("a%3Ds3cret%2F%21&")
  end

  it "generates a signature based on consumer_secret and token_secret" do
    # example taken from https://developer.twitter.com/en/docs/basics/authentication/guides/creating-a-signature.html
    signature_base_string = "POST&https%3A%2F%2Fapi.twitter.com%2F1.1%2Fstatuses%2Fupdate.json&include_entities%3Dtrue%26oauth_consumer_key%3Dxvz1evFS4wEEPTGEFPHBog%26oauth_nonce%3DkYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1318622958%26oauth_token%3D370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb%26oauth_version%3D1.0%26status%3DHello%2520Ladies%2520%252B%2520Gentlemen%252C%2520a%2520signed%2520OAuth%2520request%2521"

    signature = TwitterAuth.new(consumer_secret, token_secret).signature(signature_base_string)
    signature.should eq(expected_signature)
  end

  it "generates a signature from http method, url and parameters" do
    TwitterAuth.new(consumer_secret, token_secret)
      .signature("post", base_url, parameters)
      .should eq(expected_signature)
    
  end
  
  it "stores the signature method" do
    TwitterAuth.signature_method.should be("HMAC-SHA1")
  end

  it "can generate an oauth parameter string" do
    TwitterAuth.parameter_string(parameters).should eq(parameter_string)
  end

  it "can generate a signature_base_string" do
    expected = "POST&https%3A%2F%2Fapi.twitter.com%2F1.1%2Fstatuses%2Fupdate.json&include_entities%3Dtrue%26oauth_consumer_key%3Dxvz1evFS4wEEPTGEFPHBog%26oauth_nonce%3DkYjzVBB8Y0ZFabxSWbWovY3uYSQ2pTgmZeNu2VS4cg%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1318622958%26oauth_token%3D370773112-GmHxMAgYyLbNEtIKZeRNFsMKPR9EyMZeS9weJAEb%26oauth_version%3D1.0%26status%3DHello%2520Ladies%2520%252B%2520Gentlemen%252C%2520a%2520signed%2520OAuth%2520request%2521"

    TwitterAuth.signature_base_string("post", base_url, parameter_string).should eq(expected)
  end

  it "generates non-empty nonce" do
    TwitterAuth.nonce().empty?.should be_false
  end

  it "generates a nonce comprising only characters" do
    (TwitterAuth.nonce() =~ /[^A-Za-z]/).should be_nil
  end
end
