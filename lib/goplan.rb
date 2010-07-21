require 'rubygems'

gem 'oauth'
require 'oauth'

gem 'crack', '~> 0.1.4'
require 'crack'

require 'hashie'
require 'httparty'
require 'json'

require 'cgi'

module GoPlan
  class GoPlanError < StandardError
    attr_reader :data

    def initialize(data)
      @data = data
      super
    end
  end

  class RateLimitExceeded < GoPlanError; end
  class Unauthorized      < GoPlanError; end
  class General           < GoPlanError; end

  class Unavailable   < StandardError; end
  class InformGoPlan < StandardError; end
  class NotFound      < StandardError; end
  
  def self.configure
    yield self
      
    GoPlan.token = token
    GoPlan.secret = secret
    true
  end
  
  def self.token
    @token
  end
  
  def self.token=(token)
    @token = token
  end
  
  def self.secret
    @secret
  end
  
  def self.secret=(secret)
    @secret = secret
  end
end

directory = File.expand_path(File.dirname(__FILE__))

require File.join(directory, 'go_plan', 'api_standard_profile_request')
require File.join(directory, 'go_plan', 'url_resource')
require File.join(directory, 'go_plan', 'company')
require File.join(directory, 'go_plan', 'country')
require File.join(directory, 'go_plan', 'education')
require File.join(directory, 'go_plan', 'error')
require File.join(directory, 'go_plan', 'location')
require File.join(directory, 'go_plan', 'position')
require File.join(directory, 'go_plan', 'profile')
require File.join(directory, 'go_plan', 'update')
require File.join(directory, 'go_plan', 'network')
require File.join(directory, 'go_plan', 'people')
require File.join(directory, 'go_plan', 'connections')
require File.join(directory, 'go_plan', 'client')