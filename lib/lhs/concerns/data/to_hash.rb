require 'active_support'

class LHS::Data

  module ToHash
    extend ActiveSupport::Concern

    included do
      delegate :to_h, :to_hash, to: :_raw
    end
  end
end
