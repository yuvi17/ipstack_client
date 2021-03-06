# frozen_string_literal: true

require 'redis'
require 'ipstack_client/api_interface'
require 'ipstack_client/cacher'

module IpstackClient
  def self.configure
    yield self
  end

  def self.redis=(redis)
    return unless @enable_caching

    @redis = redis
  end

  def self.redis
    return unless @enable_caching
    @redis
  end

  def self.enable_caching=(enable_caching)
    @enable_caching = enable_caching
  end

  def self.enable_caching
    return @enable_caching if @enable_caching

    @enable_caching = false
  end

  def self.cache_period=(period)
    @cache_period = period
  end

  # by default cache stuff for 6 hours
  def self.cache_period
    @cache_period ||= 6*60*60 if @enable_caching
  end

  def self.api_key=(key)
    @api_key = key
  end

  def self.api_key
    @api_key
  end

  def self.enable_https=(enable_https)
    @enable_https = enable_https
  end

  def self.enable_https
    return @enable_https if @enable_https

    @enable_https = false
  end

  class Lookup
    def initialize
      @api_key = IpstackClient.api_key
      raise StandardError.new('API Key not specified') unless @api_key

      @enable_caching = IpstackClient.enable_caching
      if @enable_caching
        @redis = IpstackClient.redis
        @cache_period = IpstackClient.cache_period
      end
      @enable_https = IpstackClient.enable_https
      @cacher = IpstackClient::Cacher.new(@redis, @enable_caching, @cache_period)
    end

    def geoip_data ip
      @cacher.find(ip) do
        interface = IpstackClient::ApiInterface.new(ip, @api_key, @enable_https)
        interface.geoip_data
      end
    end
  end
end