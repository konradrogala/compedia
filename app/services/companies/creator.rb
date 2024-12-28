module Companies
  class Creator
    def initialize(companies_data, addresses_data)
      @companies_data = companies_data
      @addresses_data = addresses_data
    end

    def perform
      ActiveRecord::Base.transaction do
        insert_companies_and_addresses
      end
    end

    private

    attr_reader :companies_data, :addresses_data

    def insert_companies_and_addresses
      return [] if companies_data.empty?

      inserted_companies = Company.insert_all(
        companies_data,
        returning: %w[id registration_number]
      )

      company_id_map = inserted_companies&.index_by { |record| record["registration_number"] } || {}

      addresses_with_company_ids = addresses_data.map do |address|
        {
          street: address[:street],
          city: address[:city],
          postal_code: address[:postal_code],
          country: address[:country],
          company_id: company_id_map[address[:registration_number].to_i]["id"]
        }
      end

      Address.insert_all(addresses_with_company_ids) if addresses_with_company_ids.any?

      Company
        .includes(:addresses)
        .where(id: company_id_map.values.map { |record| record["id"] })
    end
  end
end
