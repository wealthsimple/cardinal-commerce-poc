# https://cardinaldocs.atlassian.net/wiki/spaces/CC/pages/1107394642/PART+1+-+API+-+Card+BIN+to+Card+Number+in+API+to+BIN+Intelligence+API
class BinIntelligence
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
    @timestamp = (Time.now - timestamp_buffer).to_i
  end

  def perform_request
    RestClient.post(
      ENV.fetch('BIN_INTELLIGENCE_URL'),
      v2_request_body.to_json,
      { content_type: :json, accept: :json },
    )
  end

  def request_signature
    api_key = ENV.fetch('API_KEY')
    Base64.strict_encode64(
      Digest::SHA256.digest("#{@timestamp}#{api_key}")
    ).strip
  end

  def v2_request_body
    # {
    #   Signature: request_signature,
    #   Timestamp: @timestamp,
    #   Identifier: ENV.fetch('API_IDENTIFIER'),
    #   Algorithm: "SHA-256",
    #   # Alpha numeric value transactionId. Length 5-55 characters long
    #   TransactionId: @order_number,
    #   OrgUnitId: ENV.fetch('ORG_UNIT_ID'),
    #   Payload: {
    #     BINs: @card_number,
    #   },
    # }
    {
      "Signature": "rDblGQSJujgHEeuvqTbJjB6Fktsodddiri6+F5do9cA=",
      "Timestamp": "2018-08-12T14:23:02.941Z",
      "Identifier": "aalkjdfalkdjfaslkdj",
      "Algorithm": "SHA-256",
      "TransactionId": "132456789",
      "OrgUnitId": "565607c18b111e058463ds8r",
      "Payload": {
        "BINs": "44444444"
      }
    }
  end
end
