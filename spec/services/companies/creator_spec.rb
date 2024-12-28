require 'rails_helper'

RSpec.describe Companies::Creator do
  describe '#perform' do
    let(:companies_data) do
      [
        {
          name: 'Example Co',
          registration_number: '123456789'
        },
        {
          name: 'Another Co',
          registration_number: '987654321'
        }
      ]
    end

    let(:addresses_data) do
      [
        {
          street: '123 Main St',
          city: 'New York',
          postal_code: '10001',
          country: 'USA',
          registration_number: '123456789'
        },
        {
          street: '456 Elm St',
          city: 'Los Angeles',
          postal_code: '90001',
          country: 'USA',
          registration_number: '123456789'
        },
        {
          street: '789 Oak St',
          city: 'Chicago',
          postal_code: '60601',
          country: 'USA',
          registration_number: '987654321'
        }
      ]
    end

    it 'creates companies with their addresses' do
      result = described_class.new(companies_data, addresses_data).perform

      expect(result.count).to eq(2)
      expect(result.map(&:name)).to match_array(['Example Co', 'Another Co'])
      expect(result.map(&:registration_number)).to match_array(['123456789', '987654321'])

      example_co = result.find { |c| c.name == 'Example Co' }
      another_co = result.find { |c| c.name == 'Another Co' }

      expect(example_co.addresses.count).to eq(2)
      expect(another_co.addresses.count).to eq(1)

      expect(example_co.addresses.map(&:city)).to match_array(['New York', 'Los Angeles'])
      expect(another_co.addresses.first.city).to eq('Chicago')
    end

    context 'when companies_data is empty' do
      let(:companies_data) { [] }
      let(:addresses_data) { [] }

      it 'returns empty array' do
        result = described_class.new(companies_data, addresses_data).perform
        expect(result).to be_empty
      end
    end

    context 'when transaction fails' do
      before do
        allow(Company).to receive(:insert_all).and_raise(ActiveRecord::StatementInvalid)
      end

      it 'rolls back all changes' do
        expect {
          described_class.new(companies_data, addresses_data).perform
        }.to raise_error(ActiveRecord::StatementInvalid)

        expect(Company.count).to eq(0)
        expect(Address.count).to eq(0)
      end
    end
  end
end
