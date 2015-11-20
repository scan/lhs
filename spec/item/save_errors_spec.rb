require 'rails_helper'

describe LHS::Item do

  context 'save failed' do

    let(:datastore) { 'http://datastore-stg.lb-service.sunrise.intra.local.ch/v2' }

    before(:each) do
      LHC.config.placeholder(:datastore, datastore)
      class SomeService < LHS::Service
        endpoint ':datastore/:campaign_id/feedbacks'
        endpoint ':datastore/feedbacks'
      end
    end

    let(:old_save_error) do
      {
        "status" => 400,
        "message" => "ratings must be set when review or name or review_title is set | The property value is required; it cannot be null, empty, or blank.",
        "fields" => [
          {
            "name" => "ratings",
            "details" => [{ "code" => "REQUIRED_PROPERTY_VALUE" }]
          },{
            "name" => "recommended",
            "details" => [{"code" => "REQUIRED_PROPERTY_VALUE"}]
          }
        ]
      }
    end

    let(:new_save_error) do
      {
        "status" => 400,
        "message" => "Some data in the request body failed validation. Inspect the field errors for details.",
        "field_errors" => [ {
          "code" => "UNSUPPORTED_PROPERTY_VALUE",
          "path" => [ "gender" ],
          "message" => "The property value is unsupported. Supported values are: FEMALE, MALE"
        } ]
      }
    end 

    it 'parses old errors correctly when creation failed' do
      stub_request(:post, "#{datastore}/feedbacks")
      .to_return(status: 400, body: old_save_error.to_json)
      record = SomeService.build
      record.name = 'Steve'
      result = record.save
      expect(result).to eq false
      expect(record.errors).to be
      expect(record.name).to eq 'Steve'
      expect(record.errors.include?(:ratings)).to eq true
      expect(record.errors.include?(:recommended)).to eq true
      expect(record.errors[:ratings]).to eq ['REQUIRED_PROPERTY_VALUE']
      expect(record.errors[:recommended]).to eq ['REQUIRED_PROPERTY_VALUE']
    end

    it 'parses new errors correctly when creation failed' do
      stub_request(:post, "#{datastore}/feedbacks")
      .to_return(status: 400, body: new_save_error.to_json)
      record = SomeService.build
      record.name = 'Steve'
      result = record.save
      expect(result).to eq false
      expect(record.errors).to be
      expect(record.errors.include?(:gender)).to eq true
      expect(record.errors[:gender]).to eq ['UNSUPPORTED_PROPERTY_VALUE']
    end

  end
end
