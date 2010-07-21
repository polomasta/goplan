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
    
    def initialize(company_alias, ctoken=GoPlan.token, csecret=GoPlan.secret, options={})
      @company_alias = company_alias
      
      opts = { 
              :request_token_path => "/oauth/request_token",
              :access_token_path  => "/oauth/access_token",
              :authorize_path     => "/oauth/authorize"
            }
      @ctoken, @csecret, @consumer_options = ctoken, csecret, opts.merge(options)
      
      
      self.class.base_uri "https://#{@company_alias}.goplanapp.com/api"
    end
    
    def consumer
      @consumer ||= ::OAuth::Consumer.new(@ctoken, @csecret, {:site => 'http://goplanapp.com'}.merge(consumer_options))
    end
    
    def set_callback_url(url)
      clear_request_token
      request_token(:oauth_callback => url)
    end
    
    # Note: If using oauth with a web app, be sure to provide :oauth_callback.
    # Options:
    #   :oauth_callback => String, url that GoPlan should redirect to
    def request_token(options={})
      @request_token ||= consumer.get_request_token(options)
    end
    
    # For web apps use params[:oauth_verifier], for desktop apps,
    # use the verifier is the pin that GoPlan gives users.
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
    
    def activity(options={:format => 'json'})
      activities = get("/activities/get_all", :query => options)
      activities.map{|a| Hashie::Mash.new a['activity']}
    end
    
    def get(path, options={})
      path = self.class.base_uri+path
      response = access_token.put(path, options)
      #raise_errors(response)
      response.body
    end
    
    def put(path, options={})
      path = self.class.base_uri+path
      response = access_token.put(path, options)
     # raise_errors(response)
      response
    end
    
    def delete(path, options={})
      path = self.class.base_uri+path
      response = access_token.delete(path, options)
      #raise_errors(response)
      response
    end
  
   private
    
      def jsonify_body!(options)
        options[:body] = options[:body].to_json if options[:body]
      end
  end
end