require './environment'
require 'sinatra'

# Test card numbers for Cardinal from:
# https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/903577725/EMV+3DS+Test+Cases
CARD_NUMBERS = {
  VISA_SUCCESS: '4000000000001000',
  VISA_CHALLENGE: '4000000000001091',
  VISA_FAIL: '4000000000001018',
  MASTERCARD_SUCCESS: '5200000000001005',
  MASTERCARD_CHALLENGE: '5200000000001096',
  MASTERCARD_FAIL: '5200000000001013',
}

# https://cardinaldocs.atlassian.net/wiki/spaces/CC/pages/360668/Cardinal+Cruise+Hybrid
get '/' do
  order_number = "wsorder_#{SecureRandom.uuid}"
  order_amount = 12345
  order_currency_code = "840"

  cardinal_jwt = CardinalJwt.new(
    order_number: order_number,
    order_amount: order_amount,
    order_currency_code: order_currency_code,
    callback_url: "http://localhost:4567/3ds-callback-todo",
  )

  erb :index, locals: {
    cardinal_jwt: cardinal_jwt.generate_transactional_jwt,
    card_bin: CARD_NUMBERS.fetch(:VISA_CHALLENGE).first(6),
    order_number: order_number,
    order_amount: order_amount,
    order_currency_code: order_currency_code,
  }
end

# This new API endpoint will be implemented by TabaPay
post '/accounts/:account_id/proxy_cmpi_lookup' do |account_id|
  # Given the accountID, TabaPay will be able to get the card details:
  card_number = CARD_NUMBERS.fetch(:VISA_CHALLENGE)
  card_expiry_month = "02"
  card_expiry_year = "2024"
  card_currency_code = "840"

  # Params that Wealthsimple will provide in request body:
  request_body = JSON.parse(request.body.read).symbolize_keys

  cardinal_response_xml = CmpiLookup.new()
  cardinal_response_as_json = Hash.from_xml(cardinal_response_xml).as_json

  content_type :json
  JSON.dump(cardinal_response_as_json)
end
