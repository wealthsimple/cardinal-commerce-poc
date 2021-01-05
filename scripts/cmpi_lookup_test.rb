# Usage: bundle exec ruby scripts/cmpi_lookup_test.rb
# See https://github.com/jaechow/cardinal/blob/master/centinel/lookup/cmpi00.php for PHP example
require './environment'

# Cardinal Sandbox credentials:
api_key = ENV.fetch('API_KEY')
api_id = ENV.fetch('API_IDENTIFIER')
org_unit = ENV.fetch('ORG_UNIT_ID')

# Generate the request signature as documented under:
# https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/1619492942/Cardinal+cmpi+Messages#Generating-a-Signature-Value
timestamp_buffer = 10000
timestamp = (Time.now.to_f * 1000).to_i - timestamp_buffer
request_signature = Base64.strict_encode64(
  Digest::SHA256.digest("#{timestamp}#{api_key}")
).strip

# Wealthsimple will provide TabaPay an AccountId, from which TabaPay can extract
# the below card details:
card_number = "4000000000001091"
card_expiry_month = "02"
card_expiry_year = "2024"
card_currency_code = "840"

# Additional details that Wealthsimple will provide to new TabaPay API endpoint:
df_reference_id = "c17dea31-9cf6-0c1b8f2d3c5"
transaction_id = "ws_transaction-0001"
transaction_amount = "12345"
billing_address = {
  street1: "4 Jersey St",
  street2: "",
  city: "Boston",
  postal_code: "02215",
  state: "MA",
  country_code: "840",
}
billing_person = {
  first: "Pedro",
  last: "Martinez",
  middle: "",
  email: "cardinal.mobile.test@example.com",
}

cmpi_lookup = <<-XML
<CardinalMPI>
    <Algorithm>SHA-256</Algorithm>
    <Amount>#{transaction_amount}</Amount>
    <BillingAddress1>#{billing_address[:street1]}</BillingAddress1>
    <BillingAddress2>#{billing_address[:street2]}</BillingAddress2>
    <BillingCity>#{billing_address[:city]}</BillingCity>
    <BillingPostalCode>#{billing_address[:postal_code]}</BillingPostalCode>
    <BillingState>#{billing_address[:state]}</BillingState>
    <BillingCountryCode>#{billing_address[:country_code]}</BillingCountryCode>
    <BillingFirstName>#{billing_person[:first]}</BillingFirstName>
    <BillingMiddleName>#{billing_person[:middle]}</BillingMiddleName>
    <BillingLastName>#{billing_person[:last]}</BillingLastName>
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
    <DFReferenceId>#{df_reference_id}</DFReferenceId>
    <DeviceChannel>browser</DeviceChannel>
    <Email>#{billing_person[:email]}</Email>
    <IPAddress>67.17.219.20</IPAddress>
    <Identifier>#{api_id}</Identifier>
    <MsgType>cmpi_lookup</MsgType>
    <OrderNumber>#{transaction_id}</OrderNumber>
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

# TabaPay will proxy this XML response as-is back to Wealthsimple:
response_body = ch.body_str
puts response_body
