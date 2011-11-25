module WepayRails
  module Api
    module AccountMethods
      def create_account(params)
        response = self.class.post("#{@base_uri}/account/create", {:headers => wepay_auth_header}.merge!(:body => params))
        JSON.parse(response.body)
      end

      def get_account(account_id)
        response = self.class.post("#{@base_uri}/account", {:headers => wepay_auth_header}.merge!(:body => {:account_id => account_id}))
        JSON.parse(response.body)
      end

      def find_account(args)
        response = self.class.post("#{@base_uri}/account/find", {:headers => wepay_auth_header}.merge!(:body => args))
        JSON.parse(response.body)
      end

      def modify_account(params)
        response = self.class.put("#{@base_uri}/account/modify", {:headers => wepay_auth_header}.merge!(:body => args))
        JSON.parse(response.body)
      end

      def delete_account(account_id)
        response = self.class.post("#{@base_uri}/account/delete", {:headers => wepay_auth_header}.merge!(:body => {:account_id => account_id}))
        JSON.parse(response.body)
      end

      def get_account_balance(account_id)
        response = self.class.post("#{@base_uri}/account/balance", {:headers => wepay_auth_header}.merge!(:body => {:account_id => account_id}))
        JSON.parse(response.body)
      end
    end
  end
end