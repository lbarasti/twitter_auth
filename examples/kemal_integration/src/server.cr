require "../../../src/twitter_auth"
require "kemal"
require "uuid"

consumer_key = ENV["TWITTER_CONSUMER_KEY"]
consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
callback_url = ENV["TWITTER_CALLBACK_URL"]
callback_path = URI.parse(callback_url).path

auth_client = TwitterAPI.new(consumer_key, consumer_secret, callback_url)

Users = Hash(String, TwitterAPI::TokenPair).new
Tokens = Set(String).new

def credentials(ctx) : {String?, TwitterAPI::TokenPair?}
  app_token = ctx.request.headers["token"]?
  twitter_token = app_token.try{ Users[app_token]? }
  {app_token, twitter_token}
end

get "/" do |ctx|
  send_file ctx, "public/index.html"
end

get "/authenticate" do |ctx|
  request_token = auth_client.get_token.oauth_token
  # store the request token for later verification in the /callback-url step
  Tokens.add request_token
  ctx.redirect TwitterAPI.authenticate_url(request_token)
end

get callback_path do |ctx|
  token = ctx.params.query["oauth_token"]
  # verify that the token matches the request token stored in the step above
  halt(ctx, status_code: 400) unless Tokens.includes? token
  Tokens.delete(token)

  verifier = ctx.params.query["oauth_verifier"]
  token, secret = auth_client.upgrade_token(token, verifier)
  
  app_token = UUID.random.to_s
  # store the access token and secret - to be used for future authenticated requests to the TwitterAPI
  Users[app_token] = TwitterAPI::TokenPair.new(token, secret)

  ctx.response.headers.add "Location", "/?token=#{app_token}"
  ctx.response.status_code = 302
end

get "/verify" do |ctx|
  _, twitter_token = credentials(ctx)
  halt(ctx, status_code: 401) if twitter_token.nil?

  ctx.response.content_type = "application/json"
  auth_client.verify(twitter_token)
end

get "/logout" do |ctx|
  app_token, twitter_token = credentials(ctx)
  halt(ctx, status_code: 401) if twitter_token.nil?
  
  auth_client.invalidate_token(twitter_token)
  Users.delete(app_token)
  
  ctx.redirect "/"
end

Kemal.run 8090