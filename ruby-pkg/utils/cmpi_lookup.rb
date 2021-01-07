class CmpiLookup
  def initialize(
    card_number:,
    card_expiry_month:,
    card_expiry_year:,
    order_number:,
    order_amount:,
    order_currency_code:,
    df_reference_id:
  )
    @card_number = card_number
    @card_expiry_month = card_expiry_month
    @card_expiry_year = card_expiry_year
    @order_number = order_number
    @order_amount = order_amount
    @order_currency_code = order_currency_code
    # Iff `ReferenceId` is in initial JWT, then this must match the
    # DfReferenceId here. Otherwise, DfReferenceId should be what is
    # passed back from setupCompleteData on frontend.
    # https://cardinaldocs.atlassian.net/wiki/spaces/CC/pages/360668/Cardinal+Cruise+Hybrid
    @df_reference_id = df_reference_id
    # unix epoch time in milliseconds
    # example: 1467122891960
    # Via Cardinal contact (Jason Chow), add a small buffer to timestamp or else
    # this cmpi_lookup request sporadically fails:
    timestamp_buffer = 10000
    @timestamp = (Time.now.to_f * 1000).to_i - timestamp_buffer
  end

  def perform_request
    ch = Curl::Easy.new(ENV.fetch('TRANSACTION_URL'))
    ch.verbose = true
    ch.timeout = 10
    ch.ssl_verify_host = false
    ch.http_post(Curl::PostField.file('cmpi_msg', request_body))
    ch.body_str.strip
  end

  def request_signature
    api_key = ENV.fetch('API_KEY')
    Base64.strict_encode64(
      Digest::SHA256.digest("#{@timestamp}#{api_key}")
    ).strip
  end

  def request_body
    # TODO: other fields like address etc should be customizable
    # https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/905478187/Lookup+Request+cmpi+lookup
    %{
<CardinalMPI>
    <Algorithm>SHA-256</Algorithm>
    <Amount>#{@order_amount}</Amount>
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
    <CardExpMonth>#{@card_expiry_month}</CardExpMonth>
    <CardExpYear>#{@card_expiry_year}</CardExpYear>
    <CardNumber>#{@card_number}</CardNumber>
    <CurrencyCode>#{@order_currency_code}</CurrencyCode>
    <DFReferenceId>#{@df_reference_id}</DFReferenceId>
    <DeviceChannel>browser</DeviceChannel>
    <Email>cardinal.mobile.test@example.com</Email>
    <Identifier>#{ENV.fetch('API_IDENTIFIER')}</Identifier>
    <MsgType>cmpi_lookup</MsgType>
    <OrderNumber>#{@order_number}</OrderNumber>
    <OrgUnit>#{ENV.fetch('ORG_UNIT_ID')}</OrgUnit>
    <Signature>#{request_signature}</Signature>
    <Timestamp>#{@timestamp}</Timestamp>
    <TransactionType>C</TransactionType>
    <UserAgent>Mozilla/5.0 (Windows NT 6.1; WOW64; rv:30.0) Gecko/20100101 Firefox/30.0</UserAgent>
    <Version>1.7</Version>
</CardinalMPI>
}
  end
end
