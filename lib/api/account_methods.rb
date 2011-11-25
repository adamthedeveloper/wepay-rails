module WepayRails
  module Api
    module AccountMethods
      def create_account(params)
        self.call("/account/create", {:body => params})
      end

      def get_account(account_id)
        self.call("/account", {:body => {:account_id => account_id}})
      end

      def find_account(args)
        self.call("/account/find", {:body => args})
      end

      def modify_account(args)
        self.call("/account/modify", {:body => args})
      end

      def delete_account(account_id)
        self.call("/account/delete", {:body => {:account_id => account_id}})
      end

      def get_account_balance(account_id)
        self.call("/account/balance", {:body => {:account_id => account_id}})
      end
    end
  end
end