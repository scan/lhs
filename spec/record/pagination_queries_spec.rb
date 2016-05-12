require 'rails_helper'

describe LHS::Record do

  context 'default pagination' do
    before(:each) do
      class Record < LHS::Record
        endpoint 'http://datastore/records'
      end
    end

    it 'provides chainable pagination methods' do
      Record.page(1) # offset 100
      Record.page(2).limit(10) # offset 20 
    end
  end
end
