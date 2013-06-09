module Rack; module Throttle
  ##
  # This rate limiter strategy throttles the application by defining a
  # maximum number of allowed HTTP requests per month (by default, 100000
  # requests per month).
  #
  # Note that this strategy doesn't use a sliding time window, but rather
  # tracks requests per distinct month. This means that the throttling
  # counter is reset every minute.
  #
  # @example Allowing up to 100000 requests/month
  #   use Rack::Throttle::Monthly
  #
  # @example Allowing up to 5000 requests per month
  #   use Rack::Throttle::Monthly, :max => 5000
  #
  class Monthly < TimeWindow
    ##
    # @param  [#call]                  app
    # @param  [Hash{Symbol => Object}] options
    # @option options [Integer] :max   (60)
    def initialize(app, options = {})
      super
    end

    def default_max_value
      100000
    end

    alias_method :max_per_month, :max_per_window

    protected

    ##
    # @param  [Rack::Request] request
    # @return [String]
    def cache_key(request)
      [super, Time.now.strftime('%Y-%m')].join(':')
    end
  end
end; end
