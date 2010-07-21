require 'helper'

class OAuthTest < Test::Unit::TestCase
  should "initialize with consumer token and secret" do
    goplan = GoPlan::Client.new('token', 'secret')
    
    goplan.ctoken.should == 'token'
    goplan.csecret.should == 'secret'
  end
  
  should "set authorization path to '/oauth/authorize' by default" do
    goplan = GoPlan::Client.new('token', 'secret')
    goplan.consumer.options[:authorize_path].should == '/oauth/authorize'
  end
  
  should "have a consumer" do
    consumer = mock('oauth consumer')
    options = { 
            #:request_token_path => "/uas/oauth/requestToken",
            #:access_token_path  => "/uas/oauth/accessToken",
            :authorize_path     => "/uas/oauth/authorize",
            :site => 'http://www.goplanapp.com'
          }
    OAuth::Consumer.expects(:new).with('token', 'secret', options).returns(consumer)
    goplan = GoPlan::Client.new('token', 'secret')
    
    goplan.consumer.should == consumer
  end
  
  should "have a request token from the consumer" do
    options = { 
            #:request_token_path => "/uas/oauth/requestToken",
            #:access_token_path  => "/uas/oauth/accessToken",
            :authorize_path     => "/oauth/authorize",
            :site => 'http://www.goplanapp.com'
          }
    consumer = mock('oauth consumer')
    request_token = mock('request token')
    consumer.expects(:get_request_token).returns(request_token)
    OAuth::Consumer.expects(:new).with('token', 'secret', options).returns(consumer)
    goplan = GoPlan::Client.new('token', 'secret')
    
    goplan.request_token.should == request_token
  end
  
  context "set_callback_url" do
    should "clear request token and set the callback url" do
      consumer = mock('oauth consumer')
      request_token = mock('request token')
      options = { 
              #:request_token_path => "/uas/oauth/requestToken",
              #:access_token_path  => "/uas/oauth/accessToken",
              :authorize_path     => "/oauth/authorize",
              :site => 'http://www.goplanapp.com'
            }
      OAuth::Consumer.
        expects(:new).
        with('token', 'secret', options).
        returns(consumer)
      
      goplan = GoPlan::Client.new('token', 'secret')
      
      consumer.
        expects(:get_request_token).
        with({:oauth_callback => 'http://myapp.goplanapp.com/oauth_callback'})
      
      goplan.set_callback_url('http://myapp.goplanapp.com/oauth_callback')
    end
  end
  
  should "be able to create access token from request token, request secret and verifier" do
    goplan = GoPplan::Client.new('token', 'secret')
    consumer = OAuth::Consumer.new('token', 'secret', {:site => 'http://www.goplanapp.com'})
    goplan.stubs(:consumer).returns(consumer)
    
    access_token  = mock('access token', :token => 'atoken', :secret => 'asecret')
    request_token = mock('request token')
    request_token.
      expects(:get_access_token).
      with(:oauth_verifier => 'verifier').
      returns(access_token)
      
    OAuth::RequestToken.
      expects(:new).
      with(consumer, 'rtoken', 'rsecret').
      returns(request_token)
    
    goplan.authorize_from_request('rtoken', 'rsecret', 'verifier')
    goplan.access_token.class.should be(OAuth::AccessToken)
    goplan.access_token.token.should == 'atoken'
    goplan.access_token.secret.should == 'asecret'
  end
  
  should "be able to create access token from access token and secret" do
    goplan = GoPlan::Client.new('token', 'secret')
    consumer = OAuth::Consumer.new('token', 'secret', {:site => 'http://www.goplanapp.com'})
    goplan.stubs(:consumer).returns(consumer)
    
    goplan.authorize_from_access('atoken', 'asecret')
    goplan.access_token.class.should be(OAuth::AccessToken)
    goplan.access_token.token.should == 'atoken'
    goplan.access_token.secret.should == 'asecret'
  end
  
  should "be able to configure consumer token and consumer secret without passing to initialize" do
    GoPlan.configure do |config|
      config.token = 'consumer_token'
      config.secret = 'consumer_secret'
    end
    
    goplan = GoPlan::Client.new
    goplan.ctoken.should == 'consumer_token'
    goplan.csecret.should == 'consumer_secret'
  end
  

end