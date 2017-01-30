require 'rails_helper'

describe LHS::Record do
  context 'includes all' do
    before(:each) do
      class Customer < LHS::Record
        endpoint 'http://datastore/customers/:id'
      end
    end

    let!(:customer_request) do
      stub_request(:get, 'http://datastore/customers/1')
        .to_return(
          body: {
            contracts: { href: 'http://datastore/customers/1/contracts' }
          }.to_json
        )
    end

    let!(:contracts_request) do
      stub_request(:get, "http://datastore/customers/1/contracts?limit=100")
        .to_return(
          body: {
            items: 10.times.map do
              {
                products: { href: 'http://datastore/products' }
              }
            end,
            limit: 10,
            offset: 0,
            total: 33
          }.to_json
        )
    end

    def additional_contracts_request(offset, amount)
      stub_request(:get, "http://datastore/customers/1/contracts?limit=10&offset=#{offset}")
        .to_return(
          body: {
            items: amount.times.map do
              {
                products: { href: 'http://datastore/products' }
              }
            end,
            limit: 10,
            offset: offset,
            total: 33
          }.to_json
        )
    end

    let!(:contracts_request_page_2) do
      additional_contracts_request(10, 10)
    end

    let!(:contracts_request_page_3) do
      additional_contracts_request(20, 10)
    end

    let!(:contracts_request_page_4) do
      additional_contracts_request(30, 3)
    end

    let!(:products_request) do
      stub_request(:get, "http://datastore/products?limit=100")
        .to_return(
          body: {
            items: 10.times.map do
              { name: 'LBC' }
            end,
            limit: 10,
            offset: 0,
            total: 22
          }.to_json
        )
    end

    def additional_products_request(offset, amount)
      stub_request(:get, "http://datastore/products?limit=10&offset=#{offset}")
        .to_return(
          body: {
            items: amount.times.map do
              { name: 'LBC' }
            end,
            limit: 10,
            offset: offset,
            total: 22
          }.to_json
        )
    end

    let!(:products_request_page_2) do
      additional_products_request(10, 10)
    end

    let!(:products_request_page_3) do
      additional_products_request(20, 2)
    end

    it 'includes all linked business objects no matter pagination' do
      customer = Customer
        .includes_all(contracts: :products)
        .find(1)
      expect(customer.contracts.length).to eq 33
      expect(customer.contracts.first.products.length).to eq 22
      expect(customer_request).to have_been_requested.at_least_once
      expect(contracts_request).to have_been_requested.at_least_once
      expect(contracts_request_page_2).to have_been_requested.at_least_once
      expect(contracts_request_page_3).to have_been_requested.at_least_once
      expect(contracts_request_page_4).to have_been_requested.at_least_once
      expect(products_request).to have_been_requested.at_least_once
      expect(products_request_page_2).to have_been_requested.at_least_once
      expect(products_request_page_3).to have_been_requested.at_least_once
    end
  end
end
