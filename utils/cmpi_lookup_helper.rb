# See https://github.com/jaechow/cardinal/blob/master/centinel/lookup/cmpi00.php for full working example
class CmpiLookupHelper
  def initialize(
    card_number:,
    df_reference_id:
  )
    @card_number = card_number
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
      { cmpi_msg: "\n#{xml_body}\n" }
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
    # Base64(Sha256(Timestamp + ApiKey))
    Base64.encode64(Digest::SHA256.digest("#{@timestamp}#{ENV.fetch('API_KEY')}"))
  end

  def xml_body
    # TODO: other fields like address etc should be customizable
    # https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/905478187/Lookup+Request+cmpi+lookup
    %{
      <CardinalMPI>
        <Algorithm>SHA-256</Algorithm>
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
        <BrowserColorDepth>32</BrowserColorDepth>
        <BrowserHeader>text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8</BrowserHeader>
        <BrowserHeader>text/html,application/xhtml+xml,application/xml;q=0.9,</BrowserHeader>
        <BrowserJavaEnabled>true</BrowserJavaEnabled>
        <BrowserLanguage>English</BrowserLanguage>
        <BrowserScreenHeight>980</BrowserScreenHeight>
        <BrowserScreenWidth>1080</BrowserScreenWidth>
        <BrowserTimeZone>25200</BrowserTimeZone>
        <CardExpMonth>02</CardExpMonth>
        <CardExpYear>2024</CardExpYear>
        <CardNumber>#{@card_number}</CardNumber>
        <CurrencyCode>840</CurrencyCode>
        <DFReferenceId>c17dea31-9cf6-0c1b8f2d3c5</DFReferenceId>
        <DeviceChannel>browser</DeviceChannel>
        <Email>cardinal.mobile.test@gmail.com</Email>
        <IPAddress>67.17.219.20</IPAddress>
        <Identifier>#{ENV.fetch('API_IDENTIFIER')}</Identifier>
        <MsgType>cmpi_lookup</MsgType>
        <OrderNumber>order-0001</OrderNumber>
        <OrgUnit>#{ENV.fetch('ORG_UNIT_ID')}</OrgUnit>
        <ShippingAddress1>8100 Tyler Blvd</ShippingAddress1>
        <ShippingAddress2></ShippingAddress2>
        <ShippingCity>44060</ShippingCity>
        <ShippingCountryCode>840</ShippingCountryCode>
        <ShippingPostalCode>44060</ShippingPostalCode>
        <ShippingState>OH</ShippingState>
        <Signature>#{signature}</Signature>
        <Timestamp>#{@timestamp}</Timestamp>
        <TransactionType>C</TransactionType>
        <UserAgent>Mozilla/5.0 (Windows NT 6.1; WOW64; rv:30.0) Gecko/20100101 Firefox/30.0</UserAgent>
        <Version>1.7</Version>
      </CardinalMPI>
    }
  end
end
