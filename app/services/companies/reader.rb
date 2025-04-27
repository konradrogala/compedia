module Companies
  class Reader
    class InvalidHeadersError < StandardError; end

    def initialize(file_path)
      @file_path = file_path
      @companies_data = {}
      @addresses_data = []
      @errors = []
    end

    def perform
      begin
        CsvValidator.new(file_path).validate!
        process_csv_rows
      rescue CSV::MalformedCSVError, CsvValidator::InvalidHeadersError => e
        errors << { line: 0, errors: [ "Malformed CSV file: #{e.message}" ] }
        return [ [], [], errors ]
      end

      [ companies_data.values, addresses_data, errors ]
    end

    private

    attr_reader :file_path
    attr_accessor :companies_data, :addresses_data, :errors

    def process_csv_rows
      CSV.foreach(file_path, headers: true).with_index(1) do |row, line_number|
        process_row(row, line_number)
      end
    end

    def process_row(row, line_number)
      valid, *result = DataValidator.new(row, line_number).validate

      if valid
        company_data, address_data = result
        registration_number = company_data[:registration_number]

        companies_data[registration_number] ||= company_data
        addresses_data << address_data
      else
        errors << result.first
      end
    end
  end
end
