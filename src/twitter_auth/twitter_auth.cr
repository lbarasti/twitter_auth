require "uri"
require "openssl/hmac"

class TwitterAuth
  SignatureMethod = "HMAC-SHA1"

  def initialize(@consumer_secret : String, @token_secret : String = "")
  end

  def signing_key : String
    [@consumer_secret, @token_secret]
        .map { |secret| TwitterAuth.escape(secret)}.join("&")
  end

  def signature(data : String) : String
    binary = OpenSSL::HMAC.digest(:sha1, self.signing_key, data)
    Base64.encode(binary).chomp
  end

  def signature(http_method, base_url, parameters)
    param_string = TwitterAuth.parameter_string(parameters)
    base_string = TwitterAuth.signature_base_string(http_method, base_url, param_string)
    self.signature(base_string)
  end

  def self.parameter_string(parameters : Hash(String, String))
    parameters.map{|k,v| "#{TwitterAuth.escape(k)}=#{TwitterAuth.escape(v)}"}.sort.join("&")
  end

  def self.signature_base_string(http_method : String, base_url : String, parameter_string : String) : String
    "#{http_method.upcase}\
        &#{TwitterAuth.escape(base_url)}\
        &#{TwitterAuth.escape(parameter_string)}"
  end

  # generate a unique token your application should generate for each unique request
  def self.nonce() : String
    Random::Secure.base64(32).gsub(/[^a-zA-Z]/, "")
  end

  def self.escape(params : String) : String
    URI.encode_www_form(params, space_to_plus: false)
  end
end