module WepayRails
  module Api
    module AccountMethods
      def create_account(params)
        self.call_api("/account/create", params)
      end

      def get_account(account_id)
        self.call_api("/account", {:account_id => account_id})
      end

      def find_account(args)
        self.call_api("/account/find", args)
      end

      def modify_account(args)
        self.call_api("/account/modify", args)
      end

      def delete_account(account_id)
        self.call_api("/account/delete", {:account_id => account_id})
      end

      def get_account_balance(account_id)
        self.call_api("/account/balance", {:account_id => account_id})
      end
    end
  end
end