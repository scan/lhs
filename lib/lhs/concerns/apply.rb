require 'active_support'

module Apply
  extend ActiveSupport::Concern

  def self.apply
    binding.pry
  end
end
