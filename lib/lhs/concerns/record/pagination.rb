require 'active_support'

class LHS::Record

  module Pagination
    extend ActiveSupport::Concern
    # Kaminari-Interface
    delegate :current_page, :first_page, :last_page, :prev_page, :next_page, :limit_value, :total_pages, to: :_pagination

    def _pagination
      self.class.pagination(_data)
    end

    module ClassMethods
      def pagination(data)
        pagination_class.new(data)
      end

      def pagination_class
        case pagination_strategy.to_sym
        when :page
          PagePagination
        when :start
          StartPagination
        else
          OffsetPagination
        end
      end
    end
  end
end
