module WepayRails
  module Exceptions
    class AccessTokenError < StandardError; end
    class ExpiredTokenError < StandardError; end
  end
end