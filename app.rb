require 'active_support/all'
require 'dotenv/load'
require 'json'
require 'jwt'
require 'securerandom'
require 'sinatra'

require './utils/cardinal_jwt_helper'

get '/' do
  cardinal_jwt_helper = CardinalJwtHelper.new(
    ws_reference_id: "ws_transaction_#{SecureRandom.uuid}",
    confirm_url: "http://localhost:4567/3ds-callback-todo",
  )

  erb :index, locals: {
    authentication_jwt: cardinal_jwt_helper.authentication_jwt,
  }
end
