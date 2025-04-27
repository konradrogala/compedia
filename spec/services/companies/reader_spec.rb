require 'rails_helper'
require 'csv'

RSpec.describe Companies::Reader do
  describe '#perform' do
    let(:csv_file) { Rails.root.join('spec', 'fixtures', 'companies_with_addresses.csv') }
    let(:csv_validator) { instance_double(Companies::CsvValidator) }
    let(:csv_enumerator) { instance_double(Enumerator) }

    before do
      allow(Companies::CsvValidator).to receive(:new).with(csv_file).and_return(csv_validator)
      allow(csv_validator).to receive(:validate!)
    end

    context 'with valid data' do
      let(:row1) do
        CSV::Row.new(
          [ "name", "registration_number", "street", "city", "postal_code", "country" ],
          [ "Example Co", "123456789", "123 Main St", "New York", "10001", "USA" ]
        )
      end

      let(:row2) do
        CSV::Row.new(
          [ "name", "registration_number", "street", "city", "postal_code", "country" ],
          [ "Another Co", "987654321", "789 Oak St", "Chicago", "60601", "USA" ]
        )
      end

      let(:data_validator1) { instance_double(Companies::DataValidator) }
      let(:data_validator2) { instance_double(Companies::DataValidator) }

      before do
        allow(CSV).to receive(:foreach).with(csv_file, headers: true).and_return(csv_enumerator)
        allow(csv_enumerator).to receive(:with_index).with(1).and_yield(row1, 1).and_yield(row2, 2)

        allow(Companies::DataValidator).to receive(:new)
          .with(row1, 1)
          .and_return(data_validator1)

        allow(Companies::DataValidator).to receive(:new)
          .with(row2, 2)
          .and_return(data_validator2)

        allow(data_validator1).to receive(:validate)
          .and_return([
            true,
            { name: "Example Co", registration_number: "123456789" },
            {
              street: "123 Main St",
              city: "New York",
              postal_code: "10001",
              country: "USA",
              registration_number: "123456789"
            }
          ])

        allow(data_validator2).to receive(:validate)
          .and_return([
            true,
            { name: "Another Co", registration_number: "987654321" },
            {
              street: "789 Oak St",
              city: "Chicago",
              postal_code: "60601",
              country: "USA",
              registration_number: "987654321"
            }
          ])
      end

      it 'returns properly formatted companies and addresses data' do
        companies_data, addresses_data, errors = described_class.new(csv_file).perform

        expect(companies_data).to contain_exactly(
          {
            name: "Example Co",
            registration_number: "123456789"
          },
          {
            name: "Another Co",
            registration_number: "987654321"
          }
        )

        expect(addresses_data).to contain_exactly(
          {
            street: "123 Main St",
            city: "New York",
            postal_code: "10001",
            country: "USA",
            registration_number: "123456789"
          },
          {
            street: "789 Oak St",
            city: "Chicago",
            postal_code: "60601",
            country: "USA",
            registration_number: "987654321"
          }
        )

        expect(errors).to be_empty
      end
    end

    context 'with invalid data' do
      let(:invalid_row) do
        CSV::Row.new(
          [ "name", "registration_number", "street", "city", "postal_code", "country" ],
          [ "", "123456789", "123 Main St", "", "10001", "USA" ]
        )
      end

      let(:data_validator) { instance_double(Companies::DataValidator) }

      before do
        allow(CSV).to receive(:foreach).with(csv_file, headers: true).and_return(csv_enumerator)
        allow(csv_enumerator).to receive(:with_index).with(1).and_yield(invalid_row, 1)

        allow(Companies::DataValidator).to receive(:new)
          .with(invalid_row, 1)
          .and_return(data_validator)

        allow(data_validator).to receive(:validate)
          .and_return([
            false,
            { line: 1, errors: [ "Name can't be blank", "City can't be blank" ] }
          ])
      end

      it 'collects validation errors' do
        companies_data, addresses_data, errors = described_class.new(csv_file).perform

        expect(companies_data).to be_empty
        expect(addresses_data).to be_empty
        expect(errors).to contain_exactly(
          { line: 1, errors: [ "Name can't be blank", "City can't be blank" ] }
        )
      end
    end

    context 'with CSV validation error' do
      before do
        allow(csv_validator).to receive(:validate!)
          .and_raise(Companies::CsvValidator::InvalidHeadersError.new("Missing required headers"))
      end

      it 'returns error message' do
        companies_data, addresses_data, errors = described_class.new(csv_file).perform

        expect(companies_data).to be_empty
        expect(addresses_data).to be_empty
        expect(errors).to contain_exactly(
          { line: 0, errors: [ "Malformed CSV file: Missing required headers" ] }
        )
      end
    end

    context 'with non-existent file' do
      let(:csv_file) { 'non_existent_file.csv' }

      before do
        allow(csv_validator).to receive(:validate!)
          .and_raise(Errno::ENOENT.new("No such file"))
      end

      it 'raises an error' do
        expect {
          described_class.new(csv_file).perform
        }.to raise_error(Errno::ENOENT)
      end
    end
  end
end
