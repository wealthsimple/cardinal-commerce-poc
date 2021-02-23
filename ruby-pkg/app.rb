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

# This endpoint returns the initial metadata needed to initialize the
# Cardinal frontend library.
# https://cardinaldocs.atlassian.net/wiki/spaces/CC/pages/360668/Cardinal+Cruise+Hybrid
get '/cardinal_init_metadata' do
  order_number = "wsorder#{SecureRandom.uuid}"
  order_amount = 12345
  order_currency_code = "840"
  jti = SecureRandom.uuid

  transactional_jwt = CardinalJwt.new.generate_transactional_jwt(
    jti: jti,
    order_number: order_number,
    order_amount: order_amount,
    order_currency_code: order_currency_code,
    callback_url: "http://localhost:4567/3ds-callback-todo",
  )

  content_type :json
  JSON.dump({
    transactional_jwt: transactional_jwt,
    jti: jti,
    order_number: order_number,
    order_amount: order_amount,
    order_currency_code: order_currency_code,
  })
end

get '/device_data_collection' do
  erb :'device-data-collection'
end

# This new API endpoint will be implemented by TabaPay.
# This will return a DeviceDataCollectionUrl which is used to collect device
# metadata ahead of starting the 3DS flow.
# https://cardinaldocs.atlassian.net/wiki/spaces/CC/pages/1109065750/Option+2+-+BIN+Intelligence+API+plus+JWT
post '/accounts/:account_id/proxy_bin_intelligence' do |account_id|
  # Given the accountID, TabaPay will be able to get the card details.
  # The below card number is hard-coded for this demo purposes:
  card_number = CARD_NUMBERS.fetch(:VISA_CHALLENGE)

  # Params that Wealthsimple will provide in request body:
  request_params = JSON.parse(request.body.read).symbolize_keys

  bin_intelligence = BinIntelligence.new(
    card_number: card_number,
    order_number: request_params[:order_number],
  )
  response = bin_intelligence.v3_perform_request
  response_json = JSON.parse(response).deep_symbolize_keys
  puts "BIN Intelligence Response:", response_json

  authentication_jwt = CardinalJwt.new.generate_authentication_jwt(
    jti: request_params[:jti],
    reference_id: response_json[:Payload][:ReferenceId],
    return_url: "http://localhost:4567/3ds-callback-todo",
  )

  content_type :json
  JSON.dump({
    authentication_jwt: authentication_jwt,
    device_data_collection_url: response_json[:Payload][:DeviceDataCollectionUrl],
  })
end

# This new API endpoint will be implemented by TabaPay.
# This is used to perform a "CMPI lookup". The response will contain an ACSUrl
# and Payload field. You can use these fields to determine if you need to
# present the 3DS authentication session to the consumer.
post '/accounts/:account_id/proxy_cmpi_lookup' do |account_id|
  # Given the accountID, TabaPay will be able to get the card details.
  # The below card number is hard-coded for this demo purposes:
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
