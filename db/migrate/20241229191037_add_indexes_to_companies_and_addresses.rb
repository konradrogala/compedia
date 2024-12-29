class AddIndexesToCompaniesAndAddresses < ActiveRecord::Migration[8.0]
  def change
    add_index :companies, :registration_number, unique: true
  end
end
