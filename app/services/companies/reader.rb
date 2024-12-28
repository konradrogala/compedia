module Companies
  class Reader
    class InvalidHeadersError < StandardError; end

    def initialize(file_path)
      @file_path = file_path
    end

    def perform
      companies_data = {}
      addresses_data = []
      errors = []

      begin
        validate_csv_headers
        process_csv_rows(companies_data, addresses_data, errors)
      rescue CSV::MalformedCSVError, InvalidHeadersError => e
        errors << { line: 0, errors: ["Malformed CSV file: #{e.message}"] }
        return [[], [], errors]
      end

      [companies_data.values, addresses_data, errors]
    end

    private

    attr_reader :file_path

    def validate_csv_headers
      headers = CSV.read(file_path, headers: true).headers
      required_headers = %w[name registration_number street city postal_code country]
      missing_headers = required_headers - (headers || [])

      if missing_headers.any?
        raise InvalidHeadersError, "Missing required headers: #{missing_headers.join(', ')}"
      end
    end

    def process_csv_rows(companies_data, addresses_data, errors)
      CSV.foreach(file_path, headers: true).with_index(1) do |row, line_number|
        process_row(row, line_number, companies_data, addresses_data, errors)
      end
    end

    def process_row(row, line_number, companies_data, addresses_data, errors)
      name = row['name']
      registration_number = row['registration_number']
      street = row['street']
      city = row['city']
      postal_code = row['postal_code']
      country = row['country']

      company = Company.new(name: name, registration_number: registration_number)
      address = Address.new(
        street: street,
        city: city,
        postal_code: postal_code,
        country: country,
        company: company
      )

      if company.valid? && address.valid?
        companies_data[registration_number] ||= {
          name: name,
          registration_number: registration_number,
          created_at: Time.current,
          updated_at: Time.current
        }

        addresses_data << {
          street: street,
          city: city,
          postal_code: postal_code,
          country: country,
          registration_number: registration_number,
          created_at: Time.current,
          updated_at: Time.current
        }
      else
        errors << { line: line_number, errors: company.errors.full_messages + address.errors.full_messages }
      end
    end
  end
end
