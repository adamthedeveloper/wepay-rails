module WepayRails
  module Helpers
    module ModelHelpers

      # Create a column on one of your models where the wepay authorization code
      # will be stored to be used for future transactions. Example:

      # add_column :users, :wepay_auth_code, :string

      # Then in your model, let's say the User model, you tell wepay-rails what the column name is:
      #
      # class User < ActiveRecord::Base
      #   wepayable :wepay_auth_code
      # end
      def wepayable(*args)
        wepayable_log = File.open('/tmp/wepayable.log','a')

        wepayable_log.puts "Wepayable column is #{@@wepayable_column}"

        # @wepayable_column is initilized in the Rails::Engine now
        # and pulled from the wepay.yml file
        define_method "has_#{@@wepayable_column}?" do
          self.send(@@wepayable_column.to_sym).present?
        end

        define_method "save_#{@@wepayable_column}" do |value|
          self.update_attribute(@@wepayable_column.to_sym, value)
        end
      end

      def wepayable_column
        @@wepayable_column
      end
    end
  end
end