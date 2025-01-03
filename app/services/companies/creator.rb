module Companies
  class Creator
    class BulkInsertError < StandardError
      attr_reader :failed_records

      def initialize(failed_records)
        @failed_records = failed_records
        super("Failed to insert some records")
      end
    end

    def initialize(companies_data, addresses_data)
      @companies_data = companies_data
      @addresses_data = addresses_data
      @failed_records = { companies: [], addresses: [] }
    end

    def perform
      ActiveRecord::Base.transaction do
        insert_companies_and_addresses
      end
    rescue ActiveRecord::RecordInvalid => e
      handle_validation_error(e)
    end

    private

    attr_reader :companies_data, :addresses_data, :failed_records

    def insert_companies_and_addresses
      return [] if companies_data.empty?

      inserted_companies = Company.insert_all(
        companies_data,
        returning: %w[id registration_number],
        unique_by: :registration_number
      )

      company_id_map = inserted_companies&.index_by { |record| record["registration_number"] } || {}

      addresses_with_company_ids = map_addresses_to_companies(company_id_map)

      if addresses_with_company_ids.any?
        begin
          Address.insert_all!(addresses_with_company_ids)
        rescue ActiveRecord::RecordInvalid => e
          @failed_records[:addresses] << e.record
          raise BulkInsertError.new(@failed_records)
        end
      end

      Company
        .includes(:addresses)
        .where(id: company_id_map.values.map { |record| record["id"] })
    end

    def map_addresses_to_companies(company_id_map)
      addresses_data.map do |address|
        company_record = company_id_map[address[:registration_number]]
        next if company_record.nil?

        {
          street: address[:street],
          city: address[:city],
          postal_code: address[:postal_code],
          country: address[:country],
          company_id: company_record["id"]
        }
      end.compact
    end

    def handle_validation_error(error)
      @failed_records[:companies] << error.record if error.record.is_a?(Company)
      @failed_records[:addresses] << error.record if error.record.is_a?(Address)

      Rails.error.report(
        error,
        context: {
          failed_companies: @failed_records[:companies],
          failed_addresses: @failed_records[:addresses]
        }
      )
      raise BulkInsertError.new(@failed_records)
    end
  end
end
