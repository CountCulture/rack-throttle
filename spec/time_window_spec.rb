require 'spec_helper'

describe Rack::Throttle::TimeWindow do
  include Rack::Test::Methods

  before do
    @req = mock('request', :ip => '1.2.3.4', :path => '/foo/bar')
  end
  
  describe "max_per_window" do
    let(:app) { Rack::Throttle::TimeWindow.new(target_app ) }
    describe "and max_option returns nil" do
      it "should return default_max_value" do
        app.stub(:max_option).and_return(nil)
        app.stub(:default_max_value).and_return(42)
        app.max_per_window(@req).should == 42
      end
    end
    
    describe "and max_option returns value" do
      it "should return max_option for request" do
        app.should_receive(:max_option).with(@req).and_return(64)
        app.stub(:default_max_value).and_return(42)
        app.max_per_window(@req).should == 64
      end
    end
    
    it "should not cache value for request" do
      # NB this changes previous behaviour but we can't cache the value if we want to allow it to be
      # set depending on the request
      app.should_receive(:default_max_value).twice.and_return(42)
      app.max_per_window(@req)
      app.max_per_window(@req)
    end
  end
  
  describe "allowed?" do
    let(:app) { Rack::Throttle::TimeWindow.new(target_app ) }
    
    it "should get cached value for calculated cache_key for request" do
      app.should_receive(:cache_key).with(@req).and_return('foo:123')
      app.should_receive(:cache_get).with('foo:123')
      app.allowed?(@req)
    end 
    
    it "should increment cached value" do
      app.stub(:cache_key).and_return('foo:123')
      app.stub(:cache_get).and_return(10)
      app.should_receive(:cache_set).with('foo:123', 11)
      app.allowed?(@req)
    end 
    
    it "should return true if cached value less than max_per_window" do
      app.should_receive(:max_per_window).and_return(10)
      app.should_receive(:cache_get).and_return(9)
      app.allowed?(@req).should be_true
    end 
    
    it "should return false if cached value more than max_per_window" do
      app.should_receive(:max_per_window).and_return(10)
      app.should_receive(:cache_get).and_return(11)
      app.allowed?(@req).should be_false
    end 
    
    it "should return false if cached value same as max_per_window" do
      #... as we've used up our limit
      app.should_receive(:max_per_window).and_return(10)
      app.should_receive(:cache_get).and_return(10)
      app.allowed?(@req).should be_false
    end 
    
    it "should return true if problem setting cache" do
      # maybe this should change otherwise users could bypass API by causing a problem with the cache
      app.should_receive(:cache_set).and_raise('something happened')
      app.allowed?(@req).should be_true
    end 
    
    context "and proc passed as :skip_throttling option" do
      let(:app) { Rack::Throttle::TimeWindow.new(target_app, :skip_throttling => Proc.new{ |req| req.path.match(/baz/) } ) }
      
      context "and proc returns false" do
        it "should get cached value for calculated cache_key for request" do
          app.should_receive(:cache_key).with(@req).and_return('foo:123')
          app.should_receive(:cache_get).with('foo:123')
          app.allowed?(@req)
        end 

        it "should increment cached value" do
          app.stub(:cache_key).and_return('foo:123')
          app.stub(:cache_get).and_return(10)
          app.should_receive(:cache_set).with('foo:123', 11)
          app.allowed?(@req)
        end 
      end
      
      context "and proc returns true" do
        before do
          @bar_req = mock('request', :ip => '1.2.3.4', :path => '/bar/baz')
        end
        
        it "should not get cached value for calculated cache_key for request" do
          app.should_not_receive(:cache_key).with(@req).and_return('foo:123')
          app.should_not_receive(:cache_get).with('foo:123')
          app.allowed?(@bar_req)
        end 

        it "should not increment cached value" do
          app.stub(:cache_key).and_return('foo:123')
          app.stub(:cache_get).and_return(10)
          app.should_not_receive(:cache_set).with('foo:123', 11)
          app.allowed?(@bar_req)
        end
        
        it 'should return true' do
          app.allowed?(@bar_req).should be_true
        end
      end
      
    end
  end
  
  # Would be nicer not to test the protected method explicitly, but seemed somewhat complex, as cache_key only called from subclasses
  describe "max_option" do
    describe "with no :max given in options" do
      let(:app) { Rack::Throttle::TimeWindow.new(target_app ) }
      it "should return nil" do
        app.send(:max_option, @req).should be_nil
      end
    end
    
    describe "with :max given in options" do
      let(:app) { Rack::Throttle::TimeWindow.new(target_app, :max => 300 ) }
      it "should given in options" do
        app.send(:max_option, @req).should == 300
      end
    end
    
    describe "with proc given for :max in options" do
      let(:app) { Rack::Throttle::TimeWindow.new(target_app, :max => Proc.new{ |req| req.path.match(/foo/) ? 100 : 30 } ) }
      it "should call proc with request" do
        app.send(:max_option, @req).should == 100
        @req.stub(:path).and_return('/baz/bar')
        app.send(:max_option, @req).should == 30
      end
    end

  end
  
end