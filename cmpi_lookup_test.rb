require './environment'

timestamp_buffer = 10000
timestamp = (Time.now.to_f * 1000).to_i - timestamp_buffer
api_key = ENV.fetch('API_KEY')
api_id = ENV.fetch('API_IDENTIFIER')
org_unit = ENV.fetch('ORG_UNIT_ID')
request_signature = Base64.strict_encode64(
  Digest::SHA256.digest("#{timestamp}#{api_key}")
).strip

# Card details:
card_number = "4000000000001091"
card_expiry_month = "02"
card_expiry_year = "2024"
card_currency_code = "840"

# Details to be passed in via REST API endpoint:
order_number = "order-0001"
order_amount = "12345"

cmpi_lookup = <<-XML
<CardinalMPI>
    <Algorithm>SHA-256</Algorithm>
    <Amount>#{order_amount}</Amount>
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
    <BrowserColorDepth>32</BrowserColorDepth>
    <BrowserHeader>text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8</BrowserHeader>
    <BrowserJavaEnabled>true</BrowserJavaEnabled>
    <BrowserLanguage>en-CA</BrowserLanguage>
    <BrowserScreenHeight>980</BrowserScreenHeight>
    <BrowserScreenWidth>1080</BrowserScreenWidth>
    <BrowserTimeZone>200</BrowserTimeZone>
    <CardExpMonth>#{card_expiry_month}</CardExpMonth>
    <CardExpYear>#{card_expiry_year}</CardExpYear>
    <CardNumber>#{card_number}</CardNumber>
    <CurrencyCode>#{card_currency_code}</CurrencyCode>
    <DFReferenceId>c17dea31-9cf6-0c1b8f2d3c5</DFReferenceId>
    <DeviceChannel>browser</DeviceChannel>
    <Email>cardinal.mobile.test@example.com</Email>
    <IPAddress>67.17.219.20</IPAddress>
    <Identifier>#{api_id}</Identifier>
    <MsgType>cmpi_lookup</MsgType>
    <OrderNumber>#{order_number}</OrderNumber>
    <OrgUnit>#{org_unit}</OrgUnit>
    <Signature>#{request_signature}</Signature>
    <Timestamp>#{timestamp}</Timestamp>
    <TransactionType>C</TransactionType>
    <UserAgent>Mozilla/5.0 (Windows NT 6.1; WOW64; rv:30.0) Gecko/20100101 Firefox/30.0</UserAgent>
    <Version>1.7</Version>
</CardinalMPI>
XML

puts cmpi_lookup

ch = Curl::Easy.new("https://centineltest.cardinalcommerce.com/maps/txns.asp")
ch.verbose = true
ch.timeout = 10
ch.ssl_verify_host = false
ch.http_post(Curl::PostField.file('cmpi_msg', cmpi_lookup))
puts ch.body_str
