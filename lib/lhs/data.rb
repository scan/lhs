require File.join(__dir__, 'proxy.rb')
Dir[File.dirname(__FILE__) + '/concerns/data/*.rb'].each { |file| require file }

# Data provides functionalities to accesses information
class LHS::Data
  include Json

  delegate :instance_methods, :items_key, :limit_key, :total_key, :offset_key, to: :class

  # prevent clashing with attributes of underlying data
  attr_accessor :_proxy, :_raw, :_parent, :_record, :_request

  def initialize(input, parent = nil, record = nil, request = nil)
    self._raw = raw_from_input(input)
    self._parent = parent
    self._record = record
    self._proxy = proxy_from_input(input)
    self._request = request
  end

  # merging data
  # e.g. when loading remote data via link
  def merge_raw!(data)
    return false unless data._raw.is_a?(Hash)
    _raw.merge! data._raw
  end

  def _root
    root = self
    root = root._parent while root && root._parent
    root
  end

  def class
    _root._record
  end

  # enforce internal data structure to have deep symbolized keys
  def _raw=(raw)
    raw.to_hash.deep_symbolize_keys! if raw && raw.respond_to?(:to_hash)
    @_raw = raw
  end

  def root_item?
    root_item == self
  end

  protected

  def method_missing(name, *args, &block)
    _proxy.send(name, *args, &block)
  end

  def respond_to_missing?(name, include_all = false)
    (root_item? && instance_methods.include?(name)) ||
      _proxy.respond_to?(name, include_all)
  end

  private

  def collection_proxy?(input)
    !! (input.is_a?(Hash) && input[items_key]) || input.is_a?(Array) || _raw.is_a?(Array)
  end

  def root_item
    return if _proxy.class != LHS::Item
    root = root_item = self
    loop do
      root = root._parent
      root_item = root if root && root._proxy.is_a?(LHS::Item)
      if !(root && root._parent)
        break
      end
    end
    root_item
  end

  def root?
    _root == self
  end

  def proxy_from_input(input)
    if input.is_a? LHS::Proxy
      input
    elsif collection_proxy?(raw_from_input(input))
      LHS::Collection.new(self)
    else
      LHS::Item.new(self)
    end
  end

  def raw_from_input(input)
    if input.is_a?(String) && input.length > 0
      raw_from_json_string(input)
    elsif defined?(input._raw)
      input._raw
    elsif defined?(input._data)
      input._data._raw
    else
      raw_from_anything_else(input)
    end
  end

  def raw_from_json_string(input)
    json = JSON.parse(input)
    if json.is_a?(Hash)
      json.deep_symbolize_keys
    elsif json.is_a?(Array)
      json.map { |j| j.is_a?(Hash) ? j.deep_symbolize_keys : j }
    else
      json
    end
  end

  def raw_from_anything_else(input)
    input = input.to_hash if input.class != Hash && input.respond_to?(:to_hash)
    input.deep_symbolize_keys! if input.is_a?(Hash)
    input
  end
end
