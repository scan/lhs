require 'rails_helper'

describe LHS::Record do
  
  context 'apply' do
    before(:each) do
      class Place < LHS::Record
        endpoint 'http://datastore/places'
        endpoint 'http://datastore/places/:id'
      end
    end

    let(:access_token) { '1234' }

    it 'applies options to all request made within the apply block' do
      LHS.apply auth: { bearer: access_token } do
        Place.find(1)
      end
    end
  end
end
