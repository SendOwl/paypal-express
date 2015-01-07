module Paypal
  module Payment
    class Request::Item < Base
      attr_optional :name, :description, :amount, :number, :quantity, :category, :url, :tax_amount

      def initialize(attributes = {})
        super
        @quantity ||= 1
      end

      def to_params(parent_index, index = 0)
        params = {
          :"L_PAYMENTREQUEST_#{parent_index}_NAME#{index}" => self.name,
          :"L_PAYMENTREQUEST_#{parent_index}_DESC#{index}" => self.description,
          :"L_PAYMENTREQUEST_#{parent_index}_AMT#{index}" => Util.formatted_amount(self.amount),
          :"L_PAYMENTREQUEST_#{parent_index}_NUMBER#{index}" => self.number,
          :"L_PAYMENTREQUEST_#{parent_index}_QTY#{index}" => self.quantity,
          :"L_PAYMENTREQUEST_#{parent_index}_ITEMCATEGORY#{index}" => self.category,
          :"L_PAYMENTREQUEST_#{parent_index}_ITEMURL#{index}" => self.url
        }
        if self.tax_amount
          params[:"L_PAYMENTREQUEST_#{parent_index}_TAXAMT#{index}"] = Util.formatted_amount(self.tax_amount)
        end
        params.delete_if do |k, v|
          v.blank?
        end
        params
      end
    end
  end
end
