module WepayRails
  module Payments
    class Gateway
      include HTTParty

      base_uri @base_uri

      def initialize(*args)
        yml = Rails.root.join('config', 'wepay.yml').to_s
        @config = YAML.load_file(yml)[Rails.env].symbolize_keys
        @base_uri = Rails.env.production? ? "https://api.wepay.com" : "https://stage.wepay.com"
      end
    end

    include Wepay::Helpers::ControllerHelpers
  end

  include WepayRails::Helpers::ModelHelpers
end