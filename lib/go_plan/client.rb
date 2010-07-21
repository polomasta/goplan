module GoPlan
  class UnexpectedResponseError < RuntimeError
  end
  
  class Parser < HTTParty::Parser
    def parse
      begin
        Crack::JSON.parse(body)
      rescue => e
        raise UnexpectedResponseError, "Crack could not parse JSON. It said: #{e.message}. GoPlan's raw response: #{body}"
      end
    end
  end
  
  class Client
    include HTTParty
    
    parser GoPlan::Parser
    headers 'Content-Type' => 'application/json' 
        
    attr_reader :ctoken, :csecret, :consumer_options, :company_alias
    
    def initialize(ctoken=GoPlan.token, csecret=GoPlan.secret, company_alias, options={})
      opts = { 
              #:request_token_path => "/uas/oauth/requestToken",
              #:access_token_path  => "/uas/oauth/accessToken",
              :authorize_path     => "/oauth/authorize"
            }
      @ctoken, @csecret, @consumer_options = ctoken, csecret, opts.merge(options)
      @company_alias = company_alias
      self.class.base_uri "http://#{@company_alias}.goplanapp.com"
    end
    
    def consumer
      @consumer ||= ::OAuth::Consumer.new(@ctoken, @csecret, {:site => 'http://www.goplanapp.com'}.merge(consumer_options))
    end
    
    def set_callback_url(url)
      clear_request_token
      request_token(:oauth_callback => url)
    end
    
    # Note: If using oauth with a web app, be sure to provide :oauth_callback.
    # Options:
    #   :oauth_callback => String, url that LinkedIn should redirect to
    def request_token(options={})
      @request_token ||= consumer.get_request_token(options)
    end
    
    # For web apps use params[:oauth_verifier], for desktop apps,
    # use the verifier is the pin that LinkedIn gives users.
    def authorize_from_request(rtoken, rsecret, verifier_or_pin)
      request_token = ::OAuth::RequestToken.new(consumer, rtoken, rsecret)
      access_token = request_token.get_access_token(:oauth_verifier => verifier_or_pin)
      @atoken, @asecret = access_token.token, access_token.secret
    end
    
    def access_token
      @access_token ||= ::OAuth::AccessToken.new(consumer, @atoken, @asecret)
    end
    
    def authorize_from_access(atoken, asecret)
      @atoken, @asecret = atoken, asecret
    end
    
    #options: 
    #   id => number of items to return, defaults to 100
    #   project => project alias (alias of a specific project) - not mandatory, defaults to company scope
    
    def activiy(options={})
      activities = get("/activites/get_all.json", :query => options)
      acitivities.map{|a| Hashie::Mash.new c['activity']}
    end
  end
  
end