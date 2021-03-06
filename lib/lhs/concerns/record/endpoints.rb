require 'active_support'

class LHS::Record

  # An endpoint is an url that leads to a backend resource.
  # A record can contain multiple endpoints.
  # The endpoint that is used to request data is choosen
  # based on the provided parameters.
  module Endpoints
    extend ActiveSupport::Concern

    mattr_accessor :all

    module ClassMethods
      # Adds the endpoint to the list of endpoints.
      def endpoint(url, options = nil)
        class_attribute :endpoints unless defined? endpoints
        self.endpoints ||= []
        self.endpoints = endpoints.clone
        validates_deprecation_check!(options)
        endpoint = LHC::Endpoint.new(url, options)
        sanity_check(endpoint)
        endpoints.push(endpoint)
        LHS::Record::Endpoints.all ||= {}
        LHS::Record::Endpoints.all[url] = self
      end

      def for_url(url)
        return unless url
        _template, record = LHS::Record::Endpoints.all.detect do |template, _|
          LHC::Endpoint.match?(url, template)
        end
        record
      end

      # Find an endpoint based on the provided parameters.
      # If no parameters are provided it finds the base endpoint
      # otherwise it finds the endpoint that matches the parameters best.
      def find_endpoint(params = {}, url = nil)
        endpoint = find_best_endpoint(params) if params && params.keys.count > 0
        endpoint ||= find_endpoint_by_url(url) if url.present?
        endpoint ||= LHC::Endpoint.new(url) if url.present?
        endpoint ||= find_base_endpoint
        endpoint
      end

      # Prevent clashing endpoints.
      def sanity_check(new_endpoint)
        endpoints.each do |existing_endpoint|
          invalid = existing_endpoint.placeholders.sort == new_endpoint.placeholders.sort &&
            existing_endpoint.url != new_endpoint.url
          next unless invalid
          raise "Clashing endpoints! Cannot differentiate between #{existing_endpoint.url} and #{new_endpoint.url}"
        end
      end

      # Computes the url from params
      # by identifiying endpoint and compiles it if necessary.
      # Id in params is threaded in a special way.
      def compute_url!(params)
        endpoint = find_endpoint(params)
        url = endpoint.compile(params)
        endpoint.remove_interpolated_params!(params)
        url
      end

      private

      def validates_deprecation_check!(options)
        return unless options.present?
        return unless options[:validates].present?
        return if options[:validates].is_a?(Hash)
        return if !options[:validates].is_a?(TrueClass) && options[:validates].match(%r{^\/})
        raise 'Validates with either true or a simple string is deprecated! See here: https://github.com/local-ch/lhs#validation'
      end

      # Finds the best endpoint.
      # The best endpoint is the one where all placeholders are interpolated.
      def find_best_endpoint(params)
        sorted_endpoints.find do |endpoint|
          endpoint.placeholders.all? { |match| endpoint.find_value(match, params) }
        end
      end

      # Find endpoint by given URL
      def find_endpoint_by_url(url)
        sorted_endpoints.find do |endpoint|
          LHC::Endpoint.match?(url, endpoint.url)
        end
      end

      # Sort endpoints by number of placeholders, heighest first
      def sorted_endpoints
        endpoints.sort { |a, b| b.placeholders.count <=> a.placeholders.count }
      end

      # Finds the base endpoint.
      # A base endpoint is the one thats has the least amont of placeholers.
      # There cannot be multiple base endpoints.
      def find_base_endpoint
        endpoints = self.endpoints.group_by do |endpoint|
          endpoint.placeholders.length
        end
        bases = endpoints[endpoints.keys.min]
        raise 'Multiple base endpoints found' if bases.count > 1
        bases.first
      end
    end
  end
end
