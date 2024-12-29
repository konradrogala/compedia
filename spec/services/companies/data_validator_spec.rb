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
      end
    end

    context 'with invalid data' do
      before do
        row["name"] = ""
        row["city"] = ""
      end

      it 'returns invalid status and error messages' do
        valid, error_data = described_class.new(row, line_number).validate

        expect(valid).to be false
        expect(error_data[:line]).to eq(line_number)
        expect(error_data[:errors]).to include("Name can't be blank", "City can't be blank")
      end
    end
  end
end
