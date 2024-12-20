require 'rails_helper'

RSpec.describe Address, type: :model do
  let(:company) { Company.create!(name: "Company", registration_number: 123456) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      address = Address.new(street: "Street", city: "City", country: "Country", company: company)
      expect(address).to be_valid
    end

    it 'validates presence of street' do
      address = Address.new(street: nil, company: company, city: "City", country: "Country")
      expect(address).to_not be_valid
      expect(address.errors[:street]).to include("can't be blank")
    end

    it 'validates presence of city' do
      address = Address.new(city: nil, company: company, street: "Street", country: "Country")
      expect(address).to_not be_valid
      expect(address.errors[:city]).to include("can't be blank")
    end

    it 'validates presence of country' do
      address = Address.new(country: nil, company: company, street: "Street", city: "City")
      expect(address).to_not be_valid
      expect(address.errors[:country]).to include("can't be blank")
    end

    it 'validates presence of company' do
      address = Address.new(company: nil, street: "Street", city: "City", country: "Country")
      expect(address).to_not be_valid
      expect(address.errors[:company]).to include("must exist")
    end
  end
end
