module Rack; module Throttle
  ##
  class TimeWindow < Limiter
    ##
    # Returns `true` if fewer than the maximum number of requests permitted
    # for the current window of time have been made.
    #
    # @param  [Rack::Request] request
    # @return [Boolean]
    def allowed?(request)
      count = cache_get(key = cache_key(request)).to_i + 1 rescue 1
      allowed = count <= max_per_window(request).to_i
      begin
        cache_set(key, count)
        allowed
      rescue => e
        allowed = true
      end
    end
    
    ##
    # Stub method that should be overridden by subclasses to return
    # default maximum allow requests for this class
    #
    # @return [void]
    def default_max_value
    end
    
    ##
    # Default method that provides sensible default action for throttles that limit
    # requests to given number in a set period. Uses max valuebe overridden by subclasses to return
    # max number of requests allowed in given window. This will be set from the :max value given in
    # the options when setting the throttle. We require the Rack request to be passed in as this
    # may be used in calculating the maximum value (e.g. different values depending on whether 
    # api_token is given). Note the undocumented :max_per_hour, :max_per_minute, :max_per_day 
    # options have been removed as they duplicate the :max options, and don't add anythng
    #
    # @param  [Rack::Request] request
    # @return [Object] value
    def max_per_window(request)
      max_option(request) || default_max_value
    end
    
    protected
    def max_option(request)
      options[:max].is_a?(Proc) ? options[:max].call(request) : options[:max] 
    end
  end
end; end
