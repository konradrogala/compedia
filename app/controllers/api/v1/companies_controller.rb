class Api::V1::CompaniesController < ApplicationController
  def create
    reader = Companies::Reader.new(permit_params.path)
    companies_data, addresses_data, errors = reader.perform

    if errors.any?
      render json: { errors: errors }, status: :unprocessable_entity
      nil
    end
  end

  private

  def permit_params
    params.require(:file)
  end
end
