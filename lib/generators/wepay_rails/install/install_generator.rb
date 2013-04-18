require 'rails/generators/migration'

module WepayRails
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)
      desc "add a migration for the Wepay Rails - WepayCheckoutRecord Model - Used to capture your transactions from Wepay"
      def self.next_migration_number(path)
        unless @prev_migration_nr
          @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
        else
          @prev_migration_nr += 1
        end
        @prev_migration_nr.to_s
      end
      
      def setup_routes
        route "WepayRails.routes(self)"
      end

      def copy_migrations
        migration_template "create_wepay_checkout_records.rb", "db/migrate/create_wepay_checkout_records.rb"
        copy_file "wepay_checkout_record.rb", "app/models/wepay_checkout_record.rb"
        copy_file "wepay.yml", "config/wepay.yml.example"
      end
    end
  end
end