require File.join(File.dirname(__FILE__), "..", 'spec_helper.rb')

describe "Merb::AuthenticationHelper" do
  
  class ControllerMock < Merb::Controller
    before :ensure_authenticated
  end
  
  before(:each) do
    @controller = ControllerMock.new(fake_request)
    @request = @controller.request
    @session = @controller.session
    @controller.stub!(:session).and_return(@session)
    @session.stub!(:user).and_return("WINNA")
  end
  
  it "should not raise and Unauthenticated error" do
    lambda do
      @controller.send(:ensure_authenticated)
    end.should_not raise_error(Merb::Controller::Unauthenticated)
  end
  
  it "should raise an Unauthenticated error" do
    @controller = ControllerMock.new(Merb::Request.new({}))
    lambda do
      @controller.send(:ensure_authenticated)
    end.should raise_error(Merb::Controller::Unauthenticated)
  end
  
  it "should run the authentication when testing if it is authenticated" do
    @controller = ControllerMock.new(fake_request)
    @controller.session.should_receive(:user).and_return(nil, "WINNA")
    @controller.session.authentication.should_receive(:authenticate!).and_return("WINNA")
    @controller.send(:ensure_authenticated)
  end
  
  it "should accept and execute the provided strategies" do
    # This allows using a before filter with specific arguments
    # before :ensure_authenticated, :with => [Authenticaiton::OAuth, Merb::Authentication::BasicAuth]
    M1 = mock("m1")
    M2 = mock("m2")
    M1.stub!(:new).and_return(M1)
    M2.stub!(:new).and_return(M2)
    M1.should_receive(:abstract?).and_return(false)
    M2.should_receive(:abstract?).and_return(false)
    M1.should_receive(:run!).ordered.and_return(false)
    M2.should_receive(:run!).ordered.and_return("WINNA")
    M1.should_receive(:redirected?).and_return false
    M2.should_receive(:redirected?).and_return false
    controller = ControllerMock.new(fake_request)
    controller.session.should_receive(:user).and_return(nil, "WINNA")
    controller.send(:ensure_authenticated, [M1, M2])
  end
  
  describe "redirection" do
    
    before(:all) do
      class FooController < Merb::Controller
        before :ensure_authenticated
        
        def index; "FooController#index" end
      end
    end
    
    before(:each) do
      class MyStrategy < Merb::Authentication::Strategy
        def run!
          if params[:url]
            opts = {}
            opts[:permanent] = true if params[:permanent]
            opts[:status] = params[:status].to_i if params[:status]
            !opts.empty? ? redirect!(params[:url], opts) : redirect!(params[:url])
          elsif params[:fail]
            nil
          else
            "WINNA"
          end
        end
      end # MyStrategy
      
      Merb::Router.reset!
      Merb::Router.prepare{ match("/").to(:controller => "foo_controller")}
    end
    
    it "should redirect the controller to a Location if the strategy redirects" do
      controller = get "/", :url => "/some/url"      
      controller.headers["Location"].should == "/some/url"
    end
    
    it "should use a 302 redirection by default" do
      c = get "/", :url => "/some/url"
      c.status.should == 302
    end
    
    it "should use a 301 when marked as permanent" do
      c = get "/", :url => "/some/url", :permanent => "true"
      c.status.should == 301
    end
    
    it "should use a custom status" do
      c = get "/", :url => "/some/url", :status => 401
      c.status.should == 401
    end
    
    
  end
  
end