require 'active_support'

class LHS::Service

  module Create
    extend ActiveSupport::Concern

    module ClassMethods

      def create(data = {})
        create!(data)
        rescue LHC::Error => e
          json = JSON.parse(data.to_json)
          data = LHS::Data.new(json, nil, self.class, e.response.request)
          item = LHS::Item.new(data)
          item.errors = LHS::Errors.new(e.response)
          LHS::Data.new(item, data)
      end

      def create!(data = {})
        url = instance.compute_url!(data)
        instance.request(url: url, method: :post, body: data.to_json, headers: {'Content-Type' => 'application/json'})
      end
    end
  end
end
