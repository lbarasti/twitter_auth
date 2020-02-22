require "./consumer"
require "http"

class TumblrAPI < SimpleOAuth::Consumer
  @@request_token_url = "https://www.tumblr.com/oauth/request_token"
  @@authenticate_url = "https://www.tumblr.com/oauth/authorize?oauth_token=%s"
  @@access_token_url = "https://www.tumblr.com/oauth/access_token"
end
