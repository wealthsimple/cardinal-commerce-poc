# This script is used to perform the Cardinal cmpi_lookup request.
# https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/1619492942/Cardinal+cmpi+Messages
# Usage: bundle exec ruby scripts/cmpi_lookup_demo.rb
require './environment'

# Cardinal Sandbox credentials:
api_key = ENV.fetch('API_KEY')
api_identifier = ENV.fetch('API_IDENTIFIER')
org_unit = ENV.fetch('ORG_UNIT_ID')

# Generate the request signature as documented under:
# https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/1619492942/Cardinal+cmpi+Messages#Generating-a-Signature-Value
timestamp_buffer = 10000
timestamp = (Time.now.to_f * 1000).to_i - timestamp_buffer
request_signature = Base64.strict_encode64(Digest::SHA256.digest("#{timestamp}#{api_key}")).strip

# Wealthsimple will provide TabaPay an AccountId, from which TabaPay can extract
# the below card details.
# Sandbox card PANs can be found at https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/903577725/EMV+3DS+Test+Cases
card_number = "4000000000001091"
card_expiry_month = "02"
card_expiry_year = "2024"

# Additional details that Wealthsimple will provide to new TabaPay API endpoint:
df_reference_id = "c17dea31-9cf6-0c1b8f2d3c5"
device_channel "browser"
order_number = "ws_transaction-0001"
order_amount = "12345" # Amount is in cents
order_currency_code = "840" # 3-digit ISO country code
order_transaction_type = "C" # C = credit/debit
billing_address = {
  street1: "4 Jersey St",
  street2: "Unit 123",
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
browser_details = {
  accept_header: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  color_depth: '32',
  ip_address: '67.17.219.20',
  java_enabled: 'true',
  language: 'en-CA',
  screen_height: '980',
  screen_width: '1080',
  time_zone: '200',
  user_agent: 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:30.0) Gecko/20100101 Firefox/30.0',
}

cmpi_lookup = <<-XML
<CardinalMPI>
    <Algorithm>SHA-256</Algorithm>
    <Amount>#{order_amount}</Amount>
    <BillingAddress1>#{billing_address[:street1]}</BillingAddress1>
    <BillingAddress2>#{billing_address[:street2]}</BillingAddress2>
    <BillingCity>#{billing_address[:city]}</BillingCity>
    <BillingPostalCode>#{billing_address[:postal_code]}</BillingPostalCode>
    <BillingState>#{billing_address[:state]}</BillingState>
    <BillingCountryCode>#{billing_address[:country_code]}</BillingCountryCode>
    <BillingFirstName>#{billing_person[:first]}</BillingFirstName>
    <BillingMiddleName>#{billing_person[:middle]}</BillingMiddleName>
    <BillingLastName>#{billing_person[:last]}</BillingLastName>
    <BrowserColorDepth>#{browser_details[:color_depth]}</BrowserColorDepth>
    <BrowserHeader>#{browser_details[:accept_header]}</BrowserHeader>
    <BrowserJavaEnabled>#{browser_details[:java_enabled]}</BrowserJavaEnabled>
    <BrowserLanguage>#{browser_details[:language]}</BrowserLanguage>
    <BrowserScreenHeight>#{browser_details[:screen_height]}</BrowserScreenHeight>
    <BrowserScreenWidth>#{browser_details[:screen_width]}</BrowserScreenWidth>
    <BrowserTimeZone>#{browser_details[:time_zone]}</BrowserTimeZone>
    <CardExpMonth>#{card_expiry_month}</CardExpMonth>
    <CardExpYear>#{card_expiry_year}</CardExpYear>
    <CardNumber>#{card_number}</CardNumber>
    <CurrencyCode>#{order_currency_code}</CurrencyCode>
    <DFReferenceId>#{df_reference_id}</DFReferenceId>
    <DeviceChannel>#{device_channel}</DeviceChannel>
    <Email>#{billing_person[:email]}</Email>
    <IPAddress>#{browser_details[:ip_address]}</IPAddress>
    <Identifier>#{api_identifier}</Identifier>
    <MsgType>cmpi_lookup</MsgType>
    <OrderNumber>#{order_number}</OrderNumber>
    <OrgUnit>#{org_unit}</OrgUnit>
    <Signature>#{request_signature}</Signature>
    <Timestamp>#{timestamp}</Timestamp>
    <TransactionType>#{order_transaction_type}</TransactionType>
    <UserAgent>#{browser_details[:user_agent]}</UserAgent>
    <Version>1.7</Version>
</CardinalMPI>
XML

ch = Curl::Easy.new("https://centineltest.cardinalcommerce.com/maps/txns.asp")
ch.verbose = true
ch.http_post(Curl::PostField.file('cmpi_msg', cmpi_lookup))

# TabaPay will proxy this XML response as-is back to Wealthsimple:
response_body = ch.body_str
puts response_body.strip
