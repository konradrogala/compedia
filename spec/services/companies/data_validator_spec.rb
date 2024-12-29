require 'rails_helper'

RSpec.describe Companies::DataValidator do
  describe '#validate' do
    let(:row) do
      {
        "name" => "Example Co",
        "registration_number" => "123456789",
        "street" => "123 Main St",
        "city" => "New York",
        "postal_code" => "10001",
        "country" => "USA"
      }
    end
    let(:line_number) { 1 }

    context 'with valid data' do
      let(:company) { instance_double(Company, valid?: true) }
      let(:address) { instance_double(Address, valid?: true) }

      before do
        allow(Company).to receive(:new).and_return(company)
        allow(Address).to receive(:new).and_return(address)
      end

      it 'returns valid status and formatted data' do
        valid, company_data, address_data = described_class.new(row, line_number).validate

        expect(valid).to be true
        expect(company_data).to eq(
          name: "Example Co",
          registration_number: "123456789"
        )
        expect(address_data).to eq(
          street: "123 Main St",
          city: "New York",
          postal_code: "10001",
          country: "USA",
          registration_number: "123456789"
        )

        expect(Company).to have_received(:new).with(
          name: "Example Co",
          registration_number: "123456789"
        )

        expect(Address).to have_received(:new).with(hash_including(
          street: "123 Main St",
          city: "New York",
          postal_code: "10001",
          country: "USA",
          company: company,
          registration_number: "123456789"
        ))
      end
    end

    context 'with invalid data' do
      let(:company_errors) { instance_double(ActiveModel::Errors, full_messages: [ "Name can't be blank" ]) }
      let(:address_errors) { instance_double(ActiveModel::Errors, full_messages: [ "City can't be blank" ]) }
      let(:company) { instance_double(Company, valid?: false, errors: company_errors) }
      let(:address) { instance_double(Address, valid?: false, errors: address_errors) }

      before do
        row["name"] = ""
        row["city"] = ""

        allow(Company).to receive(:new).and_return(company)
        allow(Address).to receive(:new).and_return(address)
      end

      it 'returns invalid status and error messages' do
        valid, error_data = described_class.new(row, line_number).validate

        expect(valid).to be false
        expect(error_data[:line]).to eq(line_number)
        expect(error_data[:errors]).to include("Name can't be blank", "City can't be blank")

        expect(Company).to have_received(:new).with(
          name: "",
          registration_number: "123456789"
        )

        expect(Address).to have_received(:new).with(hash_including(
          street: "123 Main St",
          city: "",
          postal_code: "10001",
          country: "USA",
          company: company,
          registration_number: "123456789"
        ))
      end
    end
  end
end
