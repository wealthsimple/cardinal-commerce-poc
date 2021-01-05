# See https://github.com/jaechow/cardinal/blob/master/centinel/lookup/cmpi00.php for full working example
class CmpiLookupHelper
  def initialize(
    card_number:,
    order_number:,
    df_reference_id:
  )
    @card_number = card_number
    @order_number = order_number
    # Iff `ReferenceId` is in initial JWT, then this must match the
    # DfReferenceId here. Otherwise, DfReferenceId should be what is
    # passed back from setupCompleteData on frontend.
    # https://cardinaldocs.atlassian.net/wiki/spaces/CC/pages/360668/Cardinal+Cruise+Hybrid
    @df_reference_id = df_reference_id
    # unix epoch time in milliseconds
    # example: 1467122891960
    @timestamp = (Time.now.to_f * 1000).to_i
  end

  def perform_request
    connection = Faraday.new(
      "https://centineltest.cardinalcommerce.com",
      {
        ssl: { verify: false },
      },
    )
    response = connection.post(
      "/maps/txns.asp",
      "cmpi_msg=\n#{xml_body}\n"
    )
    if response.status != 200 || response.body.include?("ErrorDesc")
      p "error response:", response.status, response.body&.strip
    else
      p "success response", response.status, response.body&.strip
    end
    response
  rescue Faraday::Error => e
    p "perform_request error:", e
  end

  def signature
    generate_signature(@timestamp, ENV.fetch('API_KEY'), 'sha256')
  end

  def generate_signature(timestamp, api_key, algo = 'sha256')
    # Base64(Sha256(Timestamp + ApiKey))
    signature_body = "#{timestamp}#{api_key}"
    p "Generating signature from #{signature_body}"
    digest = if algo == "sha512"
      Digest::SHA512.digest(signature_body)
    else
      Digest::SHA256.digest(signature_body)
    end
    Base64.strict_encode64(digest).strip
  end

  def xml_body
    # TODO: other fields like address etc should be customizable
    # https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/905478187/Lookup+Request+cmpi+lookup
    %{
<CardinalMPI>
    <Algorithm>SHA-512</Algorithm>
    <Amount>12345</Amount>
    <BillAddrPostCode>44060</BillAddrPostCode>
    <BillAddrState>OH</BillAddrState>
    <BillingAddress1>8100 Tyler Blvd</BillingAddress1>
    <BillingAddress2></BillingAddress2>
    <BillingCity>Mentor</BillingCity>
    <BillingCountryCode>840</BillingCountryCode>
    <BillingFirstName>John</BillingFirstName>
    <BillingFullName>John Doe</BillingFullName>
    <BillingLastName>Doe</BillingLastName>
    <BillingPostalCode>44060</BillingPostalCode>
    <BillingState>OH</BillingState>
    <BrowserHeader>text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8</BrowserHeader>
    <CardExpMonth>02</CardExpMonth>
    <CardExpYear>2023</CardExpYear>
    <CardNumber>#{@card_number}</CardNumber>
    <CurrencyCode>840</CurrencyCode>
    <DFReferenceId>#{@df_reference_id}</DFReferenceId>
    <DeviceChannel>browser</DeviceChannel>
    <Email>cardinal.mobile.test@gmail.com</Email>
    <Identifier>#{ENV.fetch('API_IDENTIFIER')}</Identifier>
    <MsgType>cmpi_lookup</MsgType>
    <OrderNumber>#{@order_number}</OrderNumber>
    <OrgUnit>#{ENV.fetch('ORG_UNIT_ID')}</OrgUnit>
    <Signature>#{signature}</Signature>
    <Timestamp>#{@timestamp}</Timestamp>
    <TransactionType>C</TransactionType>
    <UserAgent>Mozilla/5.0 (Windows NT 6.1; WOW64; rv:30.0) Gecko/20100101 Firefox/30.0</UserAgent>
    <Version>1.7</Version>
</CardinalMPI>
}
  end
end
