require 'active_record'
module WepayRails
  module Payments
    require 'helpers/controller_helpers'
    class Gateway
      include HTTParty
      base_uri Rails.env.production? ? "https://api.wepay.com" : "https://stage.wepay.com"

      attr_accessor :wepay_auth_code

      def initialize(*args)
        yml = Rails.root.join('config', 'wepay.yml').to_s
        @config = YAML.load_file(yml)[Rails.env].symbolize_keys
      end

      def wepay_auth_header
        {'Authorization' => "Bearer: #{@wepay_auth_code}"}
      end

      def wepay_user
        response = self.class.get("/v2/user", {:headers => wepay_auth_header})
        puts response.inspect
        JSON.parse(response)
      end
    end

    include WepayRails::Helpers::ControllerHelpers
  end

  require 'helpers/model_helpers'
  def self.included(base)
    base.extend WepayRails::Helpers::ModelHelpers
  end
end
ActiveRecord::Base.send(:include, WepayRails)