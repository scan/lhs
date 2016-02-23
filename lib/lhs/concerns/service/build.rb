require 'active_support'

class LHS::Service

  module Build
    extend ActiveSupport::Concern

    module ClassMethods

      def build(data = {})
        data = LHS::Data.new(data, nil, self)
        item = LHS::Item.new(data)
        LHS::Data.new(item, nil, self)
      end
      alias_method :new, :build
      
    end
  end
end