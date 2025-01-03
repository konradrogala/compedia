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

    context 'when data is valid' do
      before do
        allow(Company).to receive(:insert_all).and_return([
          { "id" => 1, "registration_number" => "123456789" },
          { "id" => 2, "registration_number" => "987654321" }
        ])
        allow(Address).to receive(:insert_all!)
        allow(Company).to receive_message_chain(:includes, :where).and_return([
          double(
            name: 'Example Co',
            registration_number: '123456789',
            addresses: [
              double(city: 'New York'),
              double(city: 'Los Angeles')
            ]
          ),
          double(
            name: 'Another Co',
            registration_number: '987654321',
            addresses: [
              double(city: 'Chicago')
            ]
          )
        ])
      end

      it 'creates companies with their addresses' do
        result = described_class.new(companies_data, addresses_data).perform

        expect(Company).to have_received(:insert_all).with(
          companies_data,
          returning: %w[id registration_number],
          unique_by: :registration_number
        )

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
    end

    context 'when companies_data is empty' do
      let(:companies_data) { [] }
      let(:addresses_data) { [] }

      it 'returns empty array' do
        result = described_class.new(companies_data, addresses_data).perform
        expect(result).to be_empty
      end
    end

    context 'when there are duplicate registration numbers' do
      let(:duplicate_companies) do
        [
          { name: 'Example Co', registration_number: '123456789' },
          { name: 'Duplicate Co', registration_number: '123456789' }
        ]
      end

      let(:duplicate_addresses) do
        [
          {
            street: '123 Main St',
            city: 'New York',
            postal_code: '10001',
            country: 'USA',
            registration_number: '123456789'
          }
        ]
      end

      before do
        allow(Company).to receive(:insert_all).and_return([
          { "id" => 1, "registration_number" => "123456789" }
        ])
        allow(Address).to receive(:insert_all!)
        allow(Company).to receive_message_chain(:includes, :where).and_return([
          double(
            name: 'Example Co',
            registration_number: '123456789',
            addresses: []
          )
        ])
      end

      it 'skips duplicates and continues processing' do
        result = described_class.new(duplicate_companies, duplicate_addresses).perform
        expect(result.count).to eq(1)
        expect(result.first.name).to eq('Example Co')
      end
    end

    context 'when address validation fails' do
      before do
        allow(Company).to receive(:insert_all).and_return([
          { "id" => 1, "registration_number" => "123456789" }
        ])
        allow(Address).to receive(:insert_all!).and_raise(
          ActiveRecord::RecordInvalid.new(Address.new(city: nil))
        )
      end

      it 'raises BulkInsertError with failed records' do
        expect {
          described_class.new(companies_data, addresses_data).perform
        }.to raise_error(Companies::Creator::BulkInsertError) do |error|
          expect(error.failed_records[:addresses]).to be_present
          expect(error.failed_records[:addresses].first).to be_an(Address)
        end
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
      end
    end
  end
end
