require File.join(__dir__, 'proxy.rb')

# A link is pointing to a backend resource.
# Sometimes a link contains data already.
class LHS::Link < LHS::Proxy

  # prevent clashing with attributes of underlying data
  attr_accessor :_href_, :_data_, :_parent_, :_loaded_

  def initialize(href, data, parent = nil)
    self._href_ = href
    self._data_ = data
    self._parent_ = parent
    self._loaded_ = false
  end

  def reload!
    fetch
  end

  protected

  def method_missing(name, *args, &block)
    if !_loaded_ && !_data_._raw_[name.to_s]
      fetch
      self.send(name, args, block)
    else
      _data_.send(name, args, block)
    end
  end

  private

  def fetch
    request = LHS::Request.new(
      url: _href_,
      method: :get
    )
    _data_.merge!(request.data)
    self._loaded_ = true
  end
end