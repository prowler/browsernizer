module Browsernizer

  class Router
    def initialize(app, &block)
      @app = app
      @config = Config.new
      yield(@config)
    end

    def call(env)
      @env = env

      if html_request? && !on_redirection_path? && unsupported?
        [307, {"Content-Type" => "text/plain", "Location" => @config.get_location}, []]
      elsif html_request? && on_redirection_path? && !unsupported?
        [303, {"Content-Type" => "text/plain", "Location" => "/"}, []]
      else
        @app.call(env)
      end
    end

  private
    def html_request?
      @env["HTTP_ACCEPT"] && @env["HTTP_ACCEPT"].include?("text/html")
    end

    def on_redirection_path?
      @env["PATH_INFO"] && @env["PATH_INFO"] == @config.get_location
    end

    # supported by default
    def unsupported?
      agent = ::UserAgent.parse @env["HTTP_USER_AGENT"]
      @config.get_supported.detect do |supported_browser|
        if agent.browser.to_s.downcase == supported_browser.browser.to_s.downcase
          a = BrowserVersion.new agent.version.to_s
          b = BrowserVersion.new supported_browser.version.to_s
          a < b
        end
        # TODO: when useragent is fixed you can use just this line instead the above
        # agent < supported_browser
      end
    end
  end

end
