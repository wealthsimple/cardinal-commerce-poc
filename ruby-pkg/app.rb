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

get '/' do
  erb :index
end

# https://cardinaldocs.atlassian.net/wiki/spaces/CC/pages/360668/Cardinal+Cruise+Hybrid
get '/3ds_metadata' do
  order_number = "wsorder_#{SecureRandom.uuid}"
  order_amount = 12345
  order_currency_code = "840"

  cardinal_jwt = CardinalJwt.new(
    order_number: order_number,
    order_amount: order_amount,
    order_currency_code: order_currency_code,
    callback_url: "http://localhost:4567/3ds-callback-todo",
  )

  content_type :json
  JSON.dump({
    cardinal_jwt: cardinal_jwt.generate_transactional_jwt,
    card_bin: CARD_NUMBERS.fetch(:VISA_CHALLENGE).first(6),
    order_number: order_number,
    order_amount: order_amount,
    order_currency_code: order_currency_code,
  })
end

# This new API endpoint will be implemented by TabaPay
post '/accounts/:account_id/proxy_cmpi_lookup' do |account_id|
  # Given the accountID, TabaPay will be able to get the card details:
  card_number = CARD_NUMBERS.fetch(:VISA_CHALLENGE)
  card_expiry_month = "02"
  card_expiry_year = "2024"

  # Params that Wealthsimple will provide in request body:
  request_params = JSON.parse(request.body.read).symbolize_keys

  cmpi_lookup = CmpiLookup.new(
    card_number: card_number,
    card_expiry_month: card_expiry_month,
    card_expiry_year: card_expiry_year,
    order_number: request_params[:order_number],
    order_amount: request_params[:order_amount],
    order_currency_code: request_params[:order_currency_code],
    df_reference_id: request_params[:df_reference_id],
  )
  cardinal_response_xml = cmpi_lookup.perform_request
  puts "CMPI Lookup Response:", cardinal_response_xml

  content_type :json
  JSON.dump(Hash.from_xml(cardinal_response_xml).as_json)
end
