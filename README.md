[![GitHub release](https://img.shields.io/github/release/lbarasti/twitter_auth.svg)](https://github.com/lbarasti/twitter_auth/releases)
![Build Status](https://github.com/lbarasti/twitter_auth/workflows/build/badge.svg)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

# twitter_auth

A library to add the **Sign in with Twitter** functionality to your Crystal web app, in a few lines of code.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  twitter_auth:
    github: lbarasti/twitter_auth
```

2. Run `shards install`

## Usage

#### Initializing a Twitter authorization client
Twitter apps are assigned a `consumer key` and a `consumer secret`. These are used to sign any request to the Twitter API.
Here is how you create a Twitter authorization client:
```crystal
require "twitter_auth"

auth_client = TwitterAPI.new(consumer_key, consumer_secret, callback_url)
```

#### Requesting an OAuth Request Token
When a user requests to sign in with Twitter, the first step for your app is to ask Twitter for an OAuth Requests Token.
```crystal
request_token = auth_client.get_token
```
Your app will then redirect the user to a Twitter-owned login screen - `TwitterAPI.authenticate_url(request_token)` - where they can authorize your app to issue requests on their behalf.

#### Upgrading to an OAuth Access Token
After the sign-in, the user is redirected to your app via a whitelisted callback URL. With the parameters included in the request, your app can now upgrade the request token to an access one.
```crystal
access_token = auth_client.upgrade_token(request_token, verifier)
```

#### Verifying a user's identity
Now that you have an OAuth Access Token, you can verify the identity of the user who signed in.
```crystal
auth_client.verify(access_token)
```
When successful, this returns a `String` in JSON format, containing information about the user, e.g. user id, Twitter handle and description.

#### Invalidating an OAuth Access Token
By design, a Twitter user's access token never expires. Nonetheless, it's likely that your app will need to invalidate the access token at some point.
```crystal
auth_client.invalidate_token(access_token)
```
This will require the user to authorize your app again, next time they try to sign in with Twitter.

--------
For more info on the `twitter_auth` API you can browse the [API docs](https://lbarasti.com/twitter_auth/docs/) pages.

## 3-legged OAuth flow
When a user clicks on the button
![Sign in with Twitter](media/sign-in-with-twitter.png "Sign in with Twitter")
your application will initiate a [3-legged OAuth flow](https://developer.twitter.com/en/docs/basics/authentication/oauth-1-0a/obtaining-user-access-tokens).

For a minimal implementation, you just need to define the following endpoints.

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
  ctx.redirect "/#some-token-here"
end
```
Remember to configure your [Twitter app](https://developer.twitter.com/en/apps/) to whitelist the callback URL.

#### Demo

You can play with a demo of the example app on [heroku](https://this-is-trimmer.herokuapp.com/).

## FAQ

#### Why do I want this?
Your users will authenticate to your app via Twitter, so that your app does not have to deal with user management and forgotten passwords.
#### Is it authentication or authorization?
The OAuth flow lets the user **authorize** your app to read information about them, so that you can **authenticate** the user into your app.
#### Can I use my own HTTP client to issue calls to the Twitter API?
Yes, you can. Just subclass `TwitterAPI` and override the [exec](https://github.com/lbarasti/twitter_auth/blob/v1.0.0/src/twitter_auth/twitter_api.cr#L101) method.

## Development

#### Running the tests
```
crystal spec
```

#### Running the example app
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
