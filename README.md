[![GitHub release](https://img.shields.io/github/release/lbarasti/twitter_auth.svg)](https://github.com/lbarasti/twitter_auth/releases)
![Build Status](https://github.com/lbarasti/twitter_auth/workflows/build/badge.svg)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

# twitter_auth

*twitter_auth* is a library that simplifies adding the **Sign in with Twitter** functionality to your Crystal web application.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  twitter_auth:
    github: lbarasti/twitter_auth
```

2. Run `shards install`

## Usage

Initialise a Twitter authentication client:
```crystal
require "twitter_auth"

auth_client = TwitterAPI.new(consumer_key, consumer_secret, callback_url)
```

If you're using Kemal or a similar library, then you can add the following endpoints to implement a [3-legged OAuth flow](https://developer.twitter.com/en/docs/basics/authentication/oauth-1-0a/obtaining-user-access-tokens).

```crystal
get "/authenticate" do |ctx|
  request_token = auth_client.get_token.oauth_token
  <your-code-here> # store the request token for later verification in the /callback-url step
  ctx.redirect TwitterAPI.authenticate_url(request_token)
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

## API Documentation

The *twitter_auth* API is documented [here](https://lbarasti.com/twitter_auth/docs/).

## Development

### Running the tests
```
crystal spec
```

### Running the example app
Before running the example app, make sure the following environment variables are defined consistently with your Twitter app settings - you can define a new Twitter app [here](https://developer.twitter.com/en/apps/):
```
TWITTER_CONSUMER_KEY
TWITTER_CONSUMER_SECRET
TWITTER_CALLBACK_URL
```
Mind that, in order to get the app to work locally, you'll need to have `localhost:8090/your-callback-path` in the app's _callback URL_ list.

Next, run the following.
```
$ cd examples/kemal_integration
$ shards install
$ crystal src/server.cr
```
Now open your browser to `http://0.0.0.0:8090` and follow your instinct :rocket:

## Contributing

1. Fork it (<https://github.com/lbarasti/twitter_auth/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [lbarasti](https://github.com/lbarasti) - creator and maintainer
