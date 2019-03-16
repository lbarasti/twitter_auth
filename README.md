# twitter_auth

TwitterAuth is a library that simplifies adding the "login with Twitter" functionality to your Crystal web application.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     twitter_auth:
       github: your-github-user/twitter_auth
   ```

2. Run `shards install`

## Usage

Assuming the credentials of your application are exposed as environment variable, the following will set up the authentication client.
```crystal
require "twitter_auth"

consumer_key = ENV["TWITTER_CONSUMER_KEY"]
consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
callback_url = ENV["TWITTER_CALLBACK_URL"]
http_client = <your implementation here>

auth_client = TwitterAPI.new(consumer_key, consumer_secret, callback_url, http_client)
```

Mind that you are required to provide your own implementation of an http client. This is to keep your project's dependencies clean.

If you're using Kemal or a similar library, then you can add the following endpoints

```crystal
get "/" do |ctx|
  if not authenticated?(ctx) # the definition of authenticated? is up to you
    ctx.redirect "/authenticate"
  end
  <your-code-here> # serve home page
end

get "/authenticate" do |ctx|
  request_token = auth_client.get_token.oauth_token
  <your-code-here> # store the request token for later verification in the /callback-url step
  ctx.redirect "https://api.twitter.com/oauth/authenticate?oauth_token=#{request_token}"
end

get "/callback-url" do |ctx|
  token = ctx.params.query["oauth_token"]
  <your-code-here> # verify that the token matches the request token stored in the step above
  verifier = ctx.params.query["oauth_verifier"]
  token, secret = auth_client.upgrade_token(token, verifier)
  <your-code-here> # store the access token and secret - to be used for future authenticated requests to the TwitterAPI
  ctx.redirect "/"
end
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/twitter_auth/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [lorenzo.barasti](https://github.com/your-github-user) - creator and maintainer
