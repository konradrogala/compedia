require 'rails_helper'
require 'csv'

RSpec.describe Companies::Reader do
  describe '#perform' do
    let(:csv_file) { Rails.root.join('spec', 'fixtures', 'companies_with_addresses.csv') }
    let(:current_time) { Time.current }

    before do
      allow(Time).to receive(:current).and_return(current_time)
    end

    context 'with valid data' do
      it 'returns properly formatted companies and addresses data' do
        companies_data, addresses_data, errors = described_class.new(csv_file).perform

        expect(companies_data).to contain_exactly(
          {
            name: 'Example Co',
            registration_number: '123456789',
            created_at: current_time,
            updated_at: current_time
          },
          {
            name: 'Another Co',
            registration_number: '987654321',
            created_at: current_time,
            updated_at: current_time
          }
        )

        expect(addresses_data).to contain_exactly(
          {
            street: '123 Main St',
            city: 'New York',
            postal_code: '10001',
            country: 'USA',
            registration_number: '123456789',
            created_at: current_time,
            updated_at: current_time
          },
          {
            street: '456 Elm St',
            city: 'Los Angeles',
            postal_code: '90001',
            country: 'USA',
            registration_number: '123456789',
            created_at: current_time,
            updated_at: current_time
          },
          {
            street: '789 Oak St',
            city: 'Chicago',
            postal_code: '60601',
            country: 'USA',
            registration_number: '987654321',
            created_at: current_time,
            updated_at: current_time
          }
        )

        expect(errors).to be_empty
      end
    end

    context 'with invalid data' do
      let(:invalid_csv_file) { Rails.root.join('spec', 'fixtures', 'invalid_companies.csv') }

      before do
        File.write(invalid_csv_file, <<~CSV)
          name,registration_number,street,city,postal_code,country
          ,123456789,123 Main St,New York,10001,USA
          Example Co,,456 Elm St,Los Angeles,90001,USA
          Another Co,987654321,789 Oak St,,60601,USA
        CSV
      end

      after do
        File.delete(invalid_csv_file) if File.exist?(invalid_csv_file)
      end

      it 'collects validation errors' do
        companies_data, addresses_data, errors = described_class.new(invalid_csv_file).perform

        expect(companies_data).to be_empty
        expect(addresses_data).to be_empty
        expect(errors).to include(
          { line: 1, errors: ["Name can't be blank"] },
          { line: 2, errors: ["Registration number can't be blank"] },
          { line: 3, errors: ["City can't be blank"] }
        )
      end
    end

    context 'with non-existent file' do
      it 'raises an error' do
        expect {
          described_class.new('non_existent_file.csv').perform
        }.to raise_error(Errno::ENOENT)
      end
    end

    context 'with malformed CSV' do
      let(:malformed_csv_file) { Rails.root.join('spec', 'fixtures', 'malformed.csv') }

      before do
        File.write(malformed_csv_file, <<~CSV)
          name,registration_number,street,city,postal_code
          Example Co,123456789,123 Main St,New York,10001,USA
        CSV
      end

      after do
        File.delete(malformed_csv_file) if File.exist?(malformed_csv_file)
      end

      it 'handles CSV parsing errors' do
        companies_data, addresses_data, errors = described_class.new(malformed_csv_file).perform
        
        expect(companies_data).to be_empty
        expect(addresses_data).to be_empty
        expect(errors).not_to be_empty
      end
    end
  end
end
