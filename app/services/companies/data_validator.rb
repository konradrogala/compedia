module Companies
  class DataValidator
    def initialize(row, line_number)
      @row = row
      @line_number = line_number
    end

    def validate
      company = Company.new(company_attributes)
      address = Address.new(address_attributes.merge(company: company))

      if company.valid? && address.valid?
        [true, company_attributes, address_attributes]
      else
        [false, { line: line_number, errors: company.errors.full_messages + address.errors.full_messages }]
      end
    end

    private

    attr_reader :row, :line_number

    def company_attributes
      {
        name: row["name"],
        registration_number: row["registration_number"]
      }
    end

    def address_attributes
      {
        street: row["street"],
        city: row["city"],
        postal_code: row["postal_code"],
        country: row["country"],
        registration_number: row["registration_number"]
      }
    end
  end
end
