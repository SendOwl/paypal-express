module Paypal
  module Payment
    class Request < Base
      attr_optional :action, :currency_code, :description, :notify_url, :billing_type, :billing_agreement_description, :billing_agreement_id, :request_id, :seller_id, :invoice_number, :custom, :ship_name, :ship_street, :ship_street2, :ship_city, :ship_state, :ship_zip, :ship_country_code
      attr_accessor :amount, :items, :custom_fields

      def initialize(attributes = {})
        @amount = if attributes[:amount].is_a?(Common::Amount)
          attributes[:amount]
        else
          Common::Amount.new(
            :total => attributes[:amount],
            :tax => attributes[:tax_amount],
            :shipping => attributes[:shipping_amount]
          )
        end
        @items = []
        Array(attributes[:items]).each do |item_attrs|
          @items << Item.new(item_attrs)
        end
        @custom_fields = attributes[:custom_fields] || {}
        super
      end

      def to_params(index = 0)
        params = {
          :"PAYMENTREQUEST_#{index}_PAYMENTACTION" => self.action,
          :"PAYMENTREQUEST_#{index}_AMT" => Util.formatted_amount(self.amount.total),
          :"PAYMENTREQUEST_#{index}_TAXAMT" => Util.formatted_amount(self.amount.tax),
          :"PAYMENTREQUEST_#{index}_SHIPPINGAMT" => Util.formatted_amount(self.amount.shipping),
          :"PAYMENTREQUEST_#{index}_CURRENCYCODE" => self.currency_code,
          :"PAYMENTREQUEST_#{index}_DESC" => self.description,
          :"PAYMENTREQUEST_#{index}_INVNUM" => self.invoice_number,
          :"PAYMENTREQUEST_#{index}_SHIPTONAME" => self.ship_name,
          :"PAYMENTREQUEST_#{index}_SHIPTOSTREET" => self.ship_street,
          :"PAYMENTREQUEST_#{index}_SHIPTOSTREET2" => self.ship_street2,
          :"PAYMENTREQUEST_#{index}_SHIPTOCITY" => self.ship_city,
          :"PAYMENTREQUEST_#{index}_SHIPTOSTATE" => self.ship_state,
          :"PAYMENTREQUEST_#{index}_SHIPTOZIP" => self.ship_zip,
          :"PAYMENTREQUEST_#{index}_SHIPTOCOUNTRYCODE" => self.ship_country_code,
          # NOTE:
          #  notify_url works only when DoExpressCheckoutPayment called.
          #  recurring payment doesn't support dynamic notify_url.
          :"PAYMENTREQUEST_#{index}_NOTIFYURL" => self.notify_url,
          :"L_BILLINGTYPE#{index}" => self.billing_type,
          :"L_BILLINGAGREEMENTDESCRIPTION#{index}" => self.billing_agreement_description,
          # FOR PARALLEL PAYMENT
          :"PAYMENTREQUEST_#{index}_PAYMENTREQUESTID" => self.request_id,
          :"PAYMENTREQUEST_#{index}_SELLERPAYPALACCOUNTID" => self.seller_id
        }
        if self.billing_type
          params[:"L_BILLINGAGREEMENTCUSTOM#{index}"] = self.custom
        else
          params[:"PAYMENTREQUEST_#{index}_CUSTOM"] = self.custom
        end
        params.delete_if do |k, v|
          v.blank?
        end
        if self.items.present?
          params[:"PAYMENTREQUEST_#{index}_ITEMAMT"] = Util.formatted_amount(self.items_amount)
          self.items.each_with_index do |item, item_index|
            params.merge! item.to_params(index, item_index)
          end
        end
        self.custom_fields.each do |key, value|
          field = key.to_s.upcase.gsub("{N}", index.to_s).to_sym
          params[field] = value
        end
        params
      end

      def items_amount
        self.items.sum do |item|
          item.quantity * BigDecimal.new(item.amount.to_s)
        end
      end
    end
  end
end
