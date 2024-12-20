require 'rails_helper'

RSpec.describe Company, type: :model do
  describe 'associations' do
    it 'validates presence of name' do
      company = Company.new(name: nil, registration_number: 123456)
      expect(company).to_not be_valid
      expect(company.errors[:name]).to include("can't be blank")
    end

    it 'validates length of name' do
      company = Company.new(name: "A" * 257, registration_number: 123456)
      expect(company).to_not be_valid
      expect(company.errors[:name]).to include("is too long (maximum is 256 characters)")
    end

    it 'validates presence of registration_number' do
      company = Company.new(name: "Company", registration_number: nil)
      expect(company).to_not be_valid
      expect(company.errors[:registration_number]).to include("can't be blank")
    end

    it 'validates uniqueness of registration_number' do
      Company.create!(name: "Company", registration_number: 123456)
      company = Company.new(name: "Company", registration_number: 123456)
      expect(company).to_not be_valid
      expect(company.errors[:registration_number]).to include("has already been taken")
    end

    it 'has many addresses' do
      company = Company.create!(name: "Company", registration_number: 123456)
      company.addresses.create!(street: "Street", city: "City", country: "Country")
      company.addresses.create!(street: "Street 2", city: "City 2", country: "Country 2")
      expect(company.addresses.count).to eq(2)
    end
  end
end
