# wepay-rails

Wepay-Rails allows your rails app to accept payments with [Wepay](http://www.wepay.com).

[![build status][travis]][travis-link]
[travis]: https://secure.travis-ci.org/adamthedeveloper/wepay-rails.png?branch=master
[travis-link]: http://travis-ci.org/adamthedeveloper/wepay-rails

## Features

* Added PREAPPROVAL and DELAYED CHARGE ability 09/2012
* Built in IPN that listens to push notifications from wepay and updates saved checkout records for you
* Allows you to fetch your access token easily through a web interface
* Built in API tools to allow you to make all wepay-api calls easily
* Built in ability to send your customers to wepay to make payments and handles their trip back for you OR use iFrame for checkouts (see Wiki https://github.com/adamthedeveloper/wepay-rails/wiki/Using-the-wepay-iframe)
* Saves the current state of every checkout
* Authorize many users to accept payments dynamically (see Wiki https://github.com/adamthedeveloper/wepay-rails/wiki/Authorize-Many-Users-Dynamically)
* Configurable

## Installation

To install it, add this to your Gemfile

```ruby
gem 'wepay-rails'
```

To create your WepayCheckoutRecord model and migration:

```console
script/rails g wepay_rails:install
```

This will create 3 files for you, a migration file for a table to hold the checkout results, the model and a wepay.yml.example file. Next run:

```console
rake db:migrate
```

WepayCheckoutRecord will be updated by wepay's IPN system as changes to the checkout change - such as the status.
Wepay-rails handles those IPN notifications for you. You can write observers watching the WepayCheckoutRecord model if you need to have
something specific occur when the checkout changes. Also, since a model is created for you, you can also track changes to it's state
through state machine or paper trail or some other gem of your liking. Hook up WepayCheckoutRecord how you like.

Modify config/wepay.yml.example to your needs and copy it to config/wepay.yml.

Assuming that you have:

1. created an account on wepay
2. created a user to accept the payments
3. created your application for your account
4. set your wepay.yml file with the info it needs to talk to the wepay api minus the access_token

You can now get your access token.

To fetch your access_token, open a browser and go to:

```console
your.railsapp.com/wepay/authorize
```

Login at the prompt or register. You will be sent back to your app and you should have gotten an access_token. Copy it to your wepay.yml
file and restart your app.

## Example

I created a controller called finalize_controller and I use it for a landing page when the customer is finished paying
their order. The other controller I created is a checkout_controller - I send my customers to it when they click checkout
in the cart. Your app is surely different than mine. Do what makes sense to you.
For now, here's a small example...

```
app
  |_ controllers
    |_ purchase
      |_ checkout_controller.rb
      |_ finalize_controller.rb
```

Tell wepay-rails where to send the customer after they come back from wepay with a complete payment. Open wepay.yml:

```ruby
after_checkout_redirect_uri: "http://www.example.com/purchase/finalize"
```

Create a controller that will send the user to wepay - notice it includes WepayRails::Payments:

```ruby
class Purchase::CheckoutController < ApplicationController
  include WepayRails::Payments

  def index
    cart = current_user.cart # EXAMPLE - get my shopping cart

    checkout_params = {
      :amount => cart.grand_total,
      :short_description => cart.short_description,
      :long_description => cart.long_description,
    }

    # Finally, send the user off to wepay so you can get paid! - CASH MONEY
    init_checkout_and_send_user_to_wepay(checkout_params)
  end
end
```

Finally, the controller I use for finalizing the checkout - AKA - the controller the user is sent back to after his/her trip back from
wepay. A checkout_id is passed in through params so you can access the WepayCheckoutRecord, make a call to
wepay to get the checkout info - whatever you want to do (See the wiki for more info on API calls):

```ruby
class Purchase::FinalizeController < ApplicationController
  def index
    # Fetch the WepayCheckoutRecord that was stored for the checkout
    wcr  = WepayCheckoutRecord.find_by_checkout_id(params[:checkout_id])

    # Example: Set the association of the wepay checkout record to my cart - then, on to order.
    cart = current_account.cart
    cart.wepay_checkout_record = wcr
    cart.save!

    # Convert cart to an order?? Move to observer of WepayCheckoutRecord??
    cart.convert_cart_to_order if wcr.state == 'authorized'

    render :text => "Hooray - you bought some widgets!"
  end
end
```

## Example of WePay Oauth

For reference, please refer to WePay's [documentation on Oauth](https://www.wepay.com/developer/reference/oauth2).

### Setup

As an example, I have the User model, view, and controller.

I have the following routes for WePay in my `config/routes.rb:

```ruby
match 'wepay_connect',  to: 'users#wepay_connect'
match 'wepay_auth',     to: 'users#wepay_auth'
```

### Controllers

The first method that we will hit in this example is `wepay_connect` in my `Users` controller:

```ruby
def wepay_connect
  wepay_gateway = WepayRails::Payments::Gateway.new
  redirect_to wepay_gateway.auth_code_url( wepay_auth_path(current_user, only_path: false) )
end
```

This will send the user to WePay's `/oauth2/authorize` uri to start the Oauth flow.

The response is an authorization code, which is used to get the user's access token.

The next method we will hit is `wepay_auth`:

```ruby
def wepay_auth
  wepay_gateway = WepayRails::Payments::Gateway.new
  access_token  = wepay_gateway.get_access_token(params[:code], wepay_auth_path(current_user, :only_path => false) )
  if current_user.update_attributes(wepay_access_token: access_token, wepay_user_id: wepay_gateway.account_id)
    flash[:success] = "Your WePay account is now connected!"
    redirect_to root_path
  end
end
```

### Start Oauth

I have this in the view, assuming that a user is currently signed in:

```ruby
link_to "Connect To WePay", wepay_connect_path
```

When the user clicks on this link, he will be prompted to start the WePay Oauth flow.

## Special Thanks to additional contributers of Wepay-Rails
* lucisferre (Chris Nicola) https://github.com/lucisferre
* mindeavor (Gilbert) https://github.com/mindeavor
* ustorf (Bernd Ustorf) https://github.com/ustorf
* dragonstarwebdesign (Steve Aquino) https://github.com/dragonstarwebdesign
* jules27 (Julie Mao) https://github.com/jules27

## Contributing to wepay-rails
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Adam Medeiros. See LICENSE.txt for further details.
