require 'rails_helper'

describe LHS::Service do

  let(:datastore) do
    'http://datastore/v2'
  end

  before(:each) do
    LHC.config.placeholder('datastore', datastore)
    class SomeService < LHS::Service
      endpoint ':datastore/v2/content-ads/:campaign_id/feedbacks'
      endpoint ':datastore/v2/feedbacks'
    end
  end

  context 'where' do

    it 'is querying relevant endpoint when using where' do
      stub_request(:get, "#{datastore}/v2/feedbacks?has_review=true").to_return(status: 200)
      SomeService.where(has_review: true)
      stub_request(:get, "#{datastore}/v2/content-ads/123/feedbacks?has_review=true").to_return(status: 200)
      SomeService.where(campaign_id: '123', has_review: true)
      stub_request(:get, "#{datastore}/v2/feedbacks").to_return(status: 200, body: '')
      SomeService.where
    end

    it 'is using params as query params explicitly when provided in params namespace' do
      stub_request(:get, "#{datastore}/v2/content-ads/123/feedbacks?campaign_id=456").to_return(status: 200)
      SomeService.where(campaign_id: '123', params: { campaign_id: '456' })
    end
  end
end