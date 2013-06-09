require 'spec_helper'

describe Rack::Throttle::Monthly do
  include Rack::Test::Methods

  let(:app) { Rack::Throttle::Monthly.new(target_app, :max => 3) }

  it "should be allowed if not seen this month" do
    get "/foo"
    last_response.body.should show_allowed_response
  end

  it "should be allowed if seen fewer than the max allowed per month" do
    2.times { get "/foo" }
    last_response.body.should show_allowed_response
  end

  it "should not be allowed if seen more times than the max allowed per month" do
    dt = Date.today
    Timecop.freeze(Date.new(dt.year, dt.month, 1)) do
      3.times { get "/foo" }
    end
    get "/foo"
    last_response.body.should show_throttled_response
  end

  it "should not count requests from previous month" do
    dt = Date.today
    Timecop.freeze(Date.new(dt.year, dt.month-1, 28)) do
      4.times { get "/foo" }
      last_response.body.should show_throttled_response
    end

    get "/foo"
    last_response.body.should show_allowed_response
  end
end