require 'active_support/all'
require 'dotenv/load'
require 'json'
require 'jwt'
require 'securerandom'
require 'sinatra'

require './utils/cardinal_jwt_helper'

# Test card numbers for Cardinal from:
# https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/903577725/EMV+3DS+Test+Cases
CARD_NUMBERS = {
  VISA_SUCCESS: '4000000000001000',
  VISA_FAIL: '4000000000001018',
  MASTERCARD_SUCCESS: '5200000000001005',
  MASTERCARD_FAIL: '5200000000001013',
}

# https://cardinaldocs.atlassian.net/wiki/spaces/CC/pages/360668/Cardinal+Cruise+Hybrid
get '/' do
  cardinal_jwt_helper = CardinalJwtHelper.new(
    ws_reference_id: "ws_transaction_#{SecureRandom.uuid}",
    callback_url: "http://localhost:4567/3ds-callback-todo",
  )

  erb :index_hybrid, locals: {
    cardinal_jwt: cardinal_jwt_helper.transactional_jwt,
    card_number: CARD_NUMBERS.fetch(:VISA_SUCCESS),
  }
end

# https://cardinaldocs.atlassian.net/wiki/spaces/CC/pages/1109065757/Option+3+-+JWT+-+Card+BIN+as+a+POST+parameter+plus+JWT
get '/option3' do
  cardinal_jwt_helper = CardinalJwtHelper.new(
    ws_reference_id: "ws_transaction_#{SecureRandom.uuid}",
    callback_url: "http://localhost:4567/3ds-callback-todo",
  )

  erb :index_option3, locals: {
    cardinal_jwt: cardinal_jwt_helper.transactional_jwt,
    card_number: CARD_NUMBERS.fetch(:VISA_SUCCESS),
  }
end
