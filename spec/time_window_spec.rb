require 'spec_helper'

describe Rack::Throttle::TimeWindow do
  include Rack::Test::Methods

  # Would be nicer not to test the protected method explicitly, but seemed somewhat complex, as cache_key only called from subclasses
  describe "max_option" do
    before do
      @req = mock('request', :ip => '1.2.3.4', :path => '/foo/bar')
    end
    
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