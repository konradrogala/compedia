class Company < ApplicationRecord
  has_many :addresses, dependent: :destroy

  validates :name, presence: true, length: { maximum: 256 }
  validates :registration_number, presence: true, uniqueness: true
end
