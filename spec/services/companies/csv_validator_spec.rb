require 'rails_helper'

RSpec.describe Companies::CsvValidator do
  describe '#validate!' do
    let(:csv_file) { Rails.root.join('spec', 'fixtures', 'companies_with_addresses.csv') }

    context 'with valid headers' do
      it 'does not raise error' do
        expect { described_class.new(csv_file).validate! }.not_to raise_error
      end
    end

    context 'with missing headers' do
      let(:csv_file) { Rails.root.join('spec', 'fixtures', 'companies_with_missing_headers.csv') }

      it 'raises InvalidHeadersError' do
        expect { described_class.new(csv_file).validate! }
          .to raise_error(described_class::InvalidHeadersError, /Missing required headers/)
      end
    end
  end
end
