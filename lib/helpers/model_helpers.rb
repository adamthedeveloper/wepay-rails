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
        @@wepayable_column ||= args.first.to_s

        File.open('/tmp/noisebytes.log','a') {|f| f.write("Args are #{args.inspect}\n")}
        File.open('/tmp/noisebytes.log','a') {|f| f.write("Column is #{@@wepayable_column}\n")}

        define_method "has_#{@@wepayable_column}?" do
          "self.#{@@wepayable_column}.present?"
        end

        define_method "save_#{@@wepayable_column}" do |value|
          "self.update_attribute(#{@@wepayable_column}, #{value})"
        end
      end

    end
  end
end