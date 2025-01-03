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
    rescue ActiveRecord::BulkInsertError => e
      handle_bulk_insert_error(e)
    end

    private

    attr_reader :companies_data, :addresses_data, :failed_records

    def insert_companies_and_addresses
      return [] if companies_data.empty?

      inserted_companies = Company.bulk_insert(
        companies_data,
        returning: %w[id registration_number],
        on_duplicate: :skip,
        error_handling: ->(failed) { @failed_records[:companies].concat(failed) }
      )

      company_id_map = inserted_companies&.index_by { |record| record["registration_number"] } || {}

      addresses_with_company_ids = map_addresses_to_companies(company_id_map)

      if addresses_with_company_ids.any?
        Address.bulk_insert(
          addresses_with_company_ids,
          error_handling: ->(failed) { @failed_records[:addresses].concat(failed) }
        )
      end

      raise BulkInsertError.new(@failed_records) if @failed_records.values.any?(&:present?)

      Company
        .includes(:addresses)
        .where(id: company_id_map.values.map { |record| record["id"] })
    end

    def map_addresses_to_companies(company_id_map)
      addresses_data.map do |address|
        company_record = company_id_map[address[:registration_number].to_i]
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

    def handle_bulk_insert_error(error)
      Rails.error.report(
        error,
        context: {
          failed_companies: @failed_records[:companies],
          failed_addresses: @failed_records[:addresses]
        }
      )
      raise error
    end
  end
end
