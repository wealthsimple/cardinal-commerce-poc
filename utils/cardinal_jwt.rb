class CardinalJwt
  # https://cardinaldocs.atlassian.net/wiki/spaces/CC/pages/196850/JWT+Creation
  # The JWT is a JWS with the signature using a SHA-256 HMAC hash algorithm. The JWT must be created server-side and sent to the front end to be injected into the JavaScript initialization code. Creating a JWT client-side is not a valid activation option. Each order should have a uniquely generated JWT associated with it.

  def initialize(order_number:, order_amount:, order_currency_code:, callback_url:)
    @order_number = order_number
    @order_amount = order_amount
    @order_currency_code = order_currency_code
    @callback_url = callback_url
  end

  def generate_transactional_jwt
    jwt_payload = {
      # JWT Id - A unique identifier for this JWT. This field should change each time a JWT is generated.
      jti: SecureRandom.uuid,
      # Issued At - The epoch time in seconds of when the JWT was generated. This allows us to determine how long a JWT has been around and whether we consider it expired or not.
      iat: Time.now.to_i,
      # Expiration - The numeric epoch time that the JWT should be consider expired. This value is ignored if its larger than 2hrs. By default we will consider any JWT older than 2hrs.
      exp: 30.minutes.from_now.to_i,
      # Issuer - An identifier of who is issuing the JWT. We use this value to contain the Api Key identifier or name.
      iss: ENV.fetch('API_IDENTIFIER'),
      # The merchant SSO OrgUnitId
      OrgUnitId: ENV.fetch('ORG_UNIT_ID'),
      Payload: {
        OrderDetails: {
          OrderNumber: @order_number,
          Amount: @order_amount,
          CurrencyCode: @order_currency_code,
        },
      },
      ObjectifyPayload: true,
      ConfirmUrl: @callback_url,
    }
    encode_jwt(jwt_payload)
  end

  private

  def encode_jwt(payload)
    jwt_secret = ENV.fetch('API_KEY')
    jwt_algorithm = 'HS256'
    JWT.encode(payload, jwt_secret, jwt_algorithm)
  end
end
