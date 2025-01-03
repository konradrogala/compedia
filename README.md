# Compedia API

A Rails API for managing companies and their addresses, featuring bulk import capabilities from CSV files.

## System Requirements

* Ruby 3.3
* Rails 8.0
* PostgreSQL

## API Endpoints

### Create Companies with Addresses from CSV

```
POST /api/v1/companies
```

#### Request Parameters

The request should be sent as `multipart/form-data` with the following parameter:

* `file`: CSV file containing company and address data

CSV file format:
```csv
name,registration_number,street,city,postal_code,country
Example Co,123456789,123 Main St,New York,10001,USA
Example Co,123456789,456 Elm St,Los Angeles,90001,USA
Another Co,987654321,789 Oak St,Chicago,60601,USA
```

#### Example Request

```bash
curl -X POST \
  http://localhost:3000/api/v1/companies \
  -H 'Content-Type: multipart/form-data' \
  -F 'file=@companies.csv'
```

#### Success Response

```json
[
  {
    "id": 1,
    "name": "Example Co",
    "registration_number": "123456789",
    "addresses": [
      {
        "id": 1,
        "street": "123 Main St",
        "city": "New York",
        "postal_code": "10001",
        "country": "USA"
      },
      {
        "id": 2,
        "street": "456 Elm St",
        "city": "Los Angeles",
        "postal_code": "90001",
        "country": "USA"
      }
    ]
  },
  {
    "id": 2,
    "name": "Another Co",
    "registration_number": "987654321",
    "addresses": [
      {
        "id": 3,
        "street": "789 Oak St",
        "city": "Chicago",
        "postal_code": "60601",
        "country": "USA"
      }
    ]
  }
]
```

Status: 200 OK

#### Error Response

```json
{
  "errors": [
    {
      "message": "Error description"
    }
  ]
}
```

Status: 422 Unprocessable Entity

## Validations

### Company
* `name`: required, maximum 256 characters
* `registration_number`: required, unique

### Address
* `street`: required
* `city`: required
* `country`: required
* `postal_code`: optional

## Duplicate Handling

* If a company with an existing registration number appears in the CSV file, it will be skipped
* All addresses will be associated with the first company with the matching registration number

## Application Setup

1. Install dependencies:
```bash
bundle install
```

2. Create and setup database:
```bash
rails db:create db:migrate
```

3. Start the server:
```bash
rails server
```

## Testing

Run the test suite:
```bash
bundle exec rspec
``` 
