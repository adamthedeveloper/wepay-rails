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
        @params = args.last if args.last.is_a?(Hash)
        @column = args.first.to_s

        define_method "has_#{@column}?" do
          "#{@column}.present?"
        end

        define_method "save_#{@column}" do |value|
          "self.update_attribute(#{@column}, #{value})"
        end
      end


    end
  end
end