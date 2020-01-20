require "../../../src/twitter_auth"
require "kemal"
require "uuid"

consumer_key = ENV["TWITTER_CONSUMER_KEY"]
consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
callback_url = ENV["TWITTER_CALLBACK_URL"]

auth_client = TwitterAPI.new(consumer_key, consumer_secret, callback_url)

Users = Hash(String, TwitterAPI::TokenResponse).new
record UserCredentials, token : String, secret : String

def authenticated?(ctx) : Bool
  auth_header = ctx.request.headers["Authorization"]?
  puts "auth_header: #{auth_header}"  
  return !auth_header.nil?
end

get "/" do |ctx|
  send_file ctx, "public/index.html"
end

get "/authenticate" do |ctx|
  request_token = auth_client.get_token.oauth_token
  # <your-code-here> # store the request token for later verification in the /callback-url step
  ctx.redirect "https://api.twitter.com/oauth/authenticate?oauth_token=#{request_token}"
end

get "/request-token-callback" do |ctx|
  token = ctx.params.query["oauth_token"]
  # <your-code-here> # verify that the token matches the request token stored in the step above
  verifier = ctx.params.query["oauth_verifier"]
  token, secret = auth_client.upgrade_token(token, verifier)
  # <your-code-here> # store the access token and secret - to be used for future authenticated requests to the TwitterAPI
  
  app_token = UUID.random.to_s
  Users[app_token] = TwitterAPI::TokenResponse.new(token, secret)

  ctx.response.headers.add "Location", "/?token=#{app_token}"
  ctx.response.status_code = 302
end

get "/verify" do |ctx|
  app_token = ctx.request.headers["token"]?
  halt(ctx, status_code: 403, response: "Forbidden") if app_token.nil?
  credentials = Users[app_token]?
  halt(ctx, status_code: 403, response: "Forbidden") if credentials.nil?
  ctx.response.content_type = "application/json"
  auth_client.verify(credentials)
end

get "/logout" do |ctx|
  app_token = ctx.request.headers["token"]?
  Users.delete(app_token)
  ctx.redirect "/"
  # TODO: call invalidate_token, https://developer.twitter.com/en/docs/basics/authentication/api-reference/invalidate_access_token
end

Kemal.run 8090