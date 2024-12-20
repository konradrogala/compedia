class Company < ApplicationRecord
  validates :name, presence: true, length: { maximum: 256 }
  validates :registration_number, presence: true, uniqueness: true
end
