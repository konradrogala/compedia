module Companies
  class CsvValidator
    class InvalidHeadersError < StandardError; end

    REQUIRED_HEADERS = %w[name registration_number street city postal_code country].freeze

    def initialize(file_path)
      @file_path = file_path
    end

    def validate!
      headers = CSV.read(file_path, headers: true).headers
      missing_headers = REQUIRED_HEADERS - (headers || [])

      if missing_headers.any?
        raise InvalidHeadersError, "Missing required headers: #{missing_headers.join(', ')}"
      end
    end

    private

    attr_reader :file_path
  end
end
