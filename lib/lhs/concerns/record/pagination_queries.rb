require 'active_support'

class LHS::Record

  module PaginationQueries
    extend ActiveSupport::Concern

    module ClassMethods
      def page(page)
        pagination = pagination_class.new(pagination_key => page)
        where(pagination_key => pagination.page_to_offset(page))
      end

      def limit(limit)
        binding.pry
        where(limit_key => limit)
      end
    end
  end
end
