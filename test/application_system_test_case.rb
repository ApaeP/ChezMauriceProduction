require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1200, 800 ] do |options|
    # Exercise the real iframe markup without resolving or loading third-party media.
    options.add_argument("--no-proxy-server")
    options.add_argument("--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE localhost, EXCLUDE 127.0.0.1")
  end
end
