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
  cardinal_jwt_helper = CardinalJwtHelper.new(
    callback_url: "http://localhost:4567/3ds-callback-todo",
  )

  erb :index, locals: {
    cardinal_jwt: cardinal_jwt_helper.transactional_jwt,
    card_number: CARD_NUMBERS.fetch(:VISA_CHALLENGE),
    order_number: cardinal_jwt_helper.order_number,
  }
end
