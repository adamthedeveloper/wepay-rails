require 'active_record'
module WepayRails
  module Payments
    require 'helpers/controller_helpers'
    class Gateway
      include HTTParty

      base_uri @base_uri

      attr_accessor :config

      def initialize(*args)
        yml = Rails.root.join('config', 'wepay.yml').to_s
        @config = YAML.load_file(yml)[Rails.env].symbolize_keys
        @base_uri = Rails.env.production? ? "https://api.wepay.com" : "https://stage.wepay.com"
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