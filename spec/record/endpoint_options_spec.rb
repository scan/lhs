require 'rails_helper'

describe LHS::Record do
  context 'set options for an endpoint' do
    before(:each) do
      class Record < LHS::Record
        endpoint 'backend/v2/feedbacks/:id', cache_expires_in: 1.day, retry: 2, cache: true
      end
    end

    it 'stores endpoints with options' do
      expect(Record.endpoints[0].options).to eq(cache_expires_in: 86400, retry: 2, cache: true)
    end

    it 'uses the options that are configured for an endpoint' do
      expect(LHC).to receive(:request).with(cache_expires_in: 1.day, retry: 2, cache: true, url: 'backend/v2/feedbacks/1').and_call_original
      stub_request(:get, "http://backend/v2/feedbacks/1").to_return(status: 200)
      Record.find(1)
    end
  end
end
