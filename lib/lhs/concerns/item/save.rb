require 'active_support'
require File.dirname(__FILE__) + '/../../proxy'

class LHS::Item < LHS::Proxy

  module Save
    extend ActiveSupport::Concern

    def save(options = nil)
      save!(options)
    rescue LHC::Error
      false
    end

    def save!(options = {})
      options = options.present? ? options.dup : {}
      data = _data._raw.dup
      url = url_for_persistance!(options, data)
      create_and_merge_data!(
        apply_default_creation_options(options, url, data)
      )
    rescue LHC::Error => e
      self.errors = LHS::Errors.new(e.response)
      raise e
    end

    private

    def apply_default_creation_options(options, url, data)
      options = options.merge(method: :post, url: url, body: data.to_json)
      options[:headers] ||= {}
      options[:headers].merge!('Content-Type' => 'application/json')
      options
    end

    def create_and_merge_data!(options)
      direct_response_data = record_for_persistance.request(options)
      _data.merge_raw!(direct_response_data)
      response_headers = direct_response_data._request.response.headers
      if response_headers && response_headers['Location']
        location_data = record_for_persistance.request(options.merge(url: response_headers['Location'], method: :get, body: nil))
        _data.merge_raw!(location_data)
      end
      true
    end

    def endpoint_for_persistance(data, options)
      record_for_persistance
        .find_endpoint(merge_data_with_options(data, options))
    end

    def merge_data_with_options(data, options)
      if options && options[:params]
        data.merge(options[:params])
      else
        data
      end
    end

    def record_for_persistance
      _data.class
    end

    def url_for_persistance!(options, data)
      return href if href.present?
      endpoint = endpoint_for_persistance(data, options)
      endpoint.compile(
        merge_data_with_options(data, options)
      ).tap do
        endpoint.remove_interpolated_params!(data)
        endpoint.remove_interpolated_params!(options.fetch(:params, {}))
        options.merge!(endpoint.options.merge(options)) if endpoint.options
      end
    end
  end
end
