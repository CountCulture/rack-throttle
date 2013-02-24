require 'spec_helper'

describe Rack::Throttle::Limiter do
  include Rack::Test::Methods

  describe 'with default config' do
    let(:app) { Rack::Throttle::Limiter.new(target_app) }

    describe "basic calling" do
      it "should return the example app" do
        get "/foo"
        last_response.body.should show_allowed_response
      end

      it "should call the application if allowed" do
        app.should_receive(:allowed?).and_return(true)
        get "/foo"
        last_response.body.should show_allowed_response
      end

      it "should give a rate limit exceeded message if not allowed" do
        app.should_receive(:allowed?).and_return(false)
        get "/foo"
        last_response.body.should show_throttled_response
      end
    end

    describe "allowed?" do
      it "should return true if whitelisted" do
        app.should_receive(:whitelisted?).and_return(true)
        get "/foo"
        last_response.body.should show_allowed_response
      end

      it "should return false if blacklisted" do
        app.should_receive(:blacklisted?).and_return(true)
        get "/foo"
        last_response.body.should show_throttled_response
      end

      it "should return true if not whitelisted or blacklisted" do
        app.should_receive(:whitelisted?).and_return(false)
        app.should_receive(:blacklisted?).and_return(false)
        get "/foo"
        last_response.body.should show_allowed_response
      end

      context "and proc passed as :skip_throttling option" do
        let(:app) { Rack::Throttle::Limiter.new(target_app, :skip_throttling => Proc.new{ |req| req.path.match(/baz/) } ) }

        context "and proc returns false" do
          it "should return true if whitelisted" do
            app.should_receive(:whitelisted?).and_return(true)
            get "/foo"
            last_response.body.should show_allowed_response
          end

          it "should return false if blacklisted" do
            app.should_receive(:blacklisted?).and_return(true)
            get "/foo"
            last_response.body.should show_throttled_response
          end
        end

        context "and proc returns false" do
          before do
            @bar_req = mock('request', :ip => '1.2.3.4', :path => '/bar/baz')
          end

          it "should ignore whitelisting" do
            app.should_not_receive(:whitelisted?)
            get "/baz"
          end

          it "should ignore blacklisting" do
            app.should_not_receive(:blacklisted?)
            get "/baz"
          end

          it 'should return true' do
            get "/baz"
            last_response.body.should_not show_throttled_response
          end
        end

      end

    end
  end

  describe 'with rate_limit_exceeded callback' do
    let(:app) { Rack::Throttle::Limiter.new(target_app, :rate_limit_exceeded_callback => lambda {|request| app.callback(request) } ) }

    it "should call rate_limit_exceeded_callback w/ request when rate limit exceeded" do
      app.should_receive(:blacklisted?).and_return(true)
      app.should_receive(:callback).and_return(true)
      get "/foo"
      last_response.body.should show_throttled_response
    end
  end

  # Would be nicer not to test the protected method explicitly, but seemed somewhat complex, as cache_key only called from subclasses
  describe ":cache_key" do
    before do
      @req = mock('request', :ip => '1.2.3.4', :path => '/foo/bar')
    end

    describe "with no cache :key_prefix supplied" do
      let(:app) { Rack::Throttle::Limiter.new(target_app ) }
      it "should use request ip address as cache_key" do
        app.send(:cache_key, @req).should == '1.2.3.4'
      end
    end

    describe "with cache :key_prefix" do
      let(:app) { Rack::Throttle::Limiter.new(target_app, :key_prefix => 'foo' ) }
      it "should join key_prefix and ip address for cache_key" do
        app.send(:cache_key, @req).should == 'foo:1.2.3.4'
      end
    end

    describe "with proc supplied for cache :key" do
      key = Proc.new { |request| 'baz' + request.path}
      let(:app) { Rack::Throttle::Limiter.new(target_app, :key => key ) }
      it "should call proc with given request" do
        app.send(:cache_key, @req).should == 'baz/foo/bar'
      end
    end
  end

  # Would be nicer not to test the protected method explicitly, but seemed somewhat complex, as cache_key only called from subclasses
  describe "client_identifier" do
    before do
      @req = mock('request', :ip => '1.2.3.4', :path => '/foo/bar')
    end

    describe "with :client_identifier supplied in options" do
      let(:app) { Rack::Throttle::Limiter.new(target_app ) }
      it "should use request ip address as client_identifier" do
        app.send(:client_identifier, @req).should == '1.2.3.4'
      end
    end

    # describe "with cache :key_prefix" do
    #   let(:app) { Rack::Throttle::Limiter.new(target_app, :key_prefix => 'foo' ) }
    #   it "should join key_prefix and ip address for cache_key" do
    #     app.send(:client_identifier, @req).should == 'foo:1.2.3.4'
    #   end
    # end

    describe "with proc supplied for :client_identifier" do
      client_identifier = Proc.new { |request| 'baz' + request.path }
      let(:app) { Rack::Throttle::Limiter.new(target_app, :client_identifier => client_identifier ) }
      it "should call proc with given request" do
        app.send(:client_identifier, @req).should == 'baz/foo/bar'
      end
    end
  end

end