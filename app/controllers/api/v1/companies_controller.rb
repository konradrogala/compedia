class Api::V1::CompaniesController < ApplicationController
  def create
    reader = Companies::Reader.new(permit_params.path)
    companies_data, addresses_data, errors = reader.perform

    if errors.any?
      render json: { errors: errors }, status: :unprocessable_entity
      return
    end

    added_companies = Companies::Creator.new(companies_data, addresses_data).perform
    render json: added_companies.as_json(include: :addresses), status: :ok
  rescue StandardError => e
    render json: { errors: [ { message: e.message } ] }, status: :unprocessable_entity
  end

  private

  def permit_params
    params.require(:file)
  end
end
