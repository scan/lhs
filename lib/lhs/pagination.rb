# Pagination is used to navigate paginateable collections
class Pagination

  delegate :_record, to: :data
  attr_accessor :data

  def initialize(data)
    self.data = data
  end

  # as standard in Rails' ActiveRecord count is not summing up, but using the number provided from data source
  def count
    total
  end

  def total
    data._raw[_record.total_key.to_sym]
  end

  def limit
    data._raw[_record.limit_key.to_sym] || LHS::Record::DEFAULT_LIMIT
  end

  def offset
    data._raw[_record.pagination_key.to_sym]
  end
  alias current_page offset
  alias start offset

  def pages_left
    total_pages - current_page
  end

  def next_offset
    fail 'to be implemented in subclass'
  end

  def current_page
    fail 'to be implemented in subclass'
  end

  def first_page
    1
  end

  def last_page
    total_pages
  end

  def prev_page
    current_page - 1
  end

  def next_page
    current_page + 1
  end

  def limit_value
    limit
  end

  def total_pages
    (total.to_f / limit).ceil
  end
end

class PagePagination < Pagination

  def current_page
    offset
  end

  def next_offset
    current_page + 1
  end

end

class StartPagination < Pagination

  def current_page
    (offset + limit - 1) / limit
  end

  def next_offset
    offset + limit
  end

end

class OffsetPagination < Pagination

  def current_page
    (offset + limit) / limit
  end

  def next_offset
    offset + limit
  end

end