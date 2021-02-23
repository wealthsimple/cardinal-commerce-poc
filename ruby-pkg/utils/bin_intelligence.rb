# https://cardinaldocs.atlassian.net/wiki/spaces/CC/pages/1107394642/PART+1+-+API+-+Card+BIN+to+Card+Number+in+API+to+BIN+Intelligence+API
class BinIntelligence
  SIGNATURE_ALGORITHM = "SHA-256".freeze

  def initialize(
    card_number:,
    order_number:
  )
    @card_number = card_number
    @order_number = order_number
    # unix epoch time in milliseconds
    # example: 1467122891960
    # Via Cardinal contact (Jason Chow), add a small buffer to timestamp or else
    # this request sporadically fails:
    timestamp_buffer = 1.second
    @timestamp = (Time.now.utc - timestamp_buffer)
  end

  # DOES NOT WORK ON STAGING. Deprecated?
  def v2_perform_request
    pp "Request body:", v2_request_body
    RestClient.post(
      ENV.fetch('BIN_INTELLIGENCE_V2_URL'),
      v2_request_body.to_json,
      { content_type: :json, accept: :json },
    )
  end

  # Response to this should look like the following:
  # {
  #   "TransactionId": "wsorder...",
  #   "ErrorNumber": 0,
  #   "Payload": {
  #     "ReferenceId":"8331f435-fa52-4e2c-8860-1fde266cd98e",
  #     "DeviceDataCollectionUrl":"https://centinelapistag.cardinalcommerce.com/V1/Cruise/Collect"
  #   }
  # }
  def v3_perform_request
    pp "Request body:", v3_request_body
    RestClient.post(
      ENV.fetch('BIN_INTELLIGENCE_V3_URL'),
      v3_request_body.to_json,
      { content_type: :json, accept: :json },
    )
  end

  def request_signature
    api_key = ENV.fetch('API_KEY')
    Base64.strict_encode64(
      Digest::SHA256.digest("#{(@timestamp.to_f * 1000).to_i}#{@order_number}#{api_key}")
    ).strip
  end

  # DOES NOT WORK ON STAGING. Deprecated?
  def v2_request_body
    # {
    #   "Signature": "rDblGQSJujgHEeuvqTbJjB6Fktsodddiri6+F5do9cA=",
    #   "Timestamp": "2018-08-12T14:23:02.941Z",
    #   "Identifier": "aalkjdfalkdjfaslkdj",
    #   "Algorithm": "SHA-256",
    #   "TransactionId": "132456789",
    #   "OrgUnitId": "565607c18b111e058463ds8r",
    #   "Payload": {
    #     "BINs": "44444444"
    #   }
    # }
    {
      Signature: request_signature,
      Timestamp: @timestamp.iso8601(3),
      Identifier: ENV.fetch('API_IDENTIFIER'),
      Algorithm: SIGNATURE_ALGORITHM,
      # Alpha numeric value transactionId. Length 5-55 characters long
      TransactionId: @order_number,
      OrgUnitId: ENV.fetch('ORG_UNIT_ID'),
      Payload: {
        BINs: @card_number,
      },
    }
  end

  def v3_request_body
    # {
    #   "Signature": "2ejC+DdvSVyRD2PnskTGw4G7rg0CqwfZNAqniChWjp0=",
    #   "Timestamp": "2018-09-19T19:04:05.104Z",
    #   "SessionId": "",
    #   "TransactionId": "132456789",
    #   "Identifier": "aalkjdfalkdjfaslkdj",
    #   "OrgUnitId": "564cdcbcb9f63f0c48d6387f",
    #   "Algorithm": "SHA-256",
    #   "Payload": {
    #     "BINs": [
    #       {
    #         "AccountNumber": "123456",
    #       }
    #     ]
    #   }
    # }
    {
      "Signature": request_signature,
      "Timestamp": @timestamp.iso8601(3),
      "SessionId": "",
      "TransactionId": @order_number,
      "Identifier": ENV.fetch('API_IDENTIFIER'),
      "OrgUnitId": ENV.fetch('ORG_UNIT_ID'),
      "Algorithm": SIGNATURE_ALGORITHM,
      "Payload": {
        "BINs": [
          {
            "AccountNumber": @card_number,
          }
        ]
      }
    }
  end
end
