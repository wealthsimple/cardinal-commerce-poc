package main

import (
	"./cmpilookup"
	"fmt"
	"os"
	"strings"
)

func main() {
	apiId := os.Getenv("API_ID")
	apiKey := os.Getenv("API_KEY")
	orgUnit := os.Getenv("ORG_UNIT")

	if apiId == "" || apiKey == "" || orgUnit == "" {
		fmt.Println("Error: Please specify Cardinal API_ID, API_KEY, and ORG_UNIT in ENV")
		os.Exit(1)
	}

	fmt.Println("Running cmpi_lookup request...")

	timestamp := cmpilookup.GetRequestTimestampWithBuffer()
	fmt.Printf("Generated request timestamp: %q\n", timestamp)

	signature, err := cmpilookup.GenerateRequestSignature(apiKey, timestamp)
	if err != nil {
		fmt.Printf("Error generating request signature: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Generated request signature: %q\n", signature)

	params := cmpilookup.RequestBodyParams{
		ApiId:            apiId,
		OrgUnit:          orgUnit,
		RequestSignature: signature,
		RequestTimestamp: timestamp,

		// Wealthsimple will provide TabaPay API endpoint with an AccountId, from
		// which TabaPay can extract the below card details.
		// Cardinal Sandbox card PANs can be found at https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/903577725/EMV+3DS+Test+Cases
		CardNumber:      "4000000000001091",
		CardExpiryMonth: "02",
		CardExpiryYear:  "2024",

		// Order detals (provided by Wealthsimple to TabaPay API endpoint)
		OrderAmount:                  "12345", // Amount is in cents
		OrderAuthenticationIndicator: "01",    // 01 = Payment
		OrderCurrencyCode:            "840",   // 3-digit ISO country code
		OrderNumber:                  "ws_transaction-0001",
		OrderProductCode:             "ACF",
		OrderTransactionMode:         "P",
		OrderTransactionType:         "C", // C: credit/debit

		// Device details (provided by Wealthsimple to TabaPay API endpoint)
		BrowserColorDepth:        "32",
		BrowserHeader:            "text/html,application/xhtml+xml,application/xml;q=0.9,",
		BrowserJavaEnabled:       "true",
		BrowserJavascriptEnabled: "true",
		BrowserLanguage:          "en-CA",
		BrowserScreenHeight:      "980",
		BrowserScreenWidth:       "1080",
		BrowserTimeZone:          "200",
		DeviceChannel:            "browser",
		DeviceReferenceId:        "c17dea31-9cf6-0c1b8f2d3c5",
		IpAddress:                "67.17.219.20",
		UserAgent:                "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:30.0) Gecko/20100101 Firefox/30.0",

		// Billing details (provided by Wealthsimple to TabaPay API endpoint)
		BillingAddressStreet1:     "4 Jersey St",
		BillingAddressStreet2:     "Unit 123",
		BillingAddressCity:        "Boston",
		BillingAddressPostalCode:  "02215",
		BillingAddressState:       "MA",
		BillingAddressCountryCode: "840",
		BillingFirstName:          "Pedro",
		BillingLastName:           "Martinez",
		BillingMiddleName:         "Jaime",
		Email:                     "cardinal.mobile.test@example.com",
		MobilePhone:               "+16175551234",
	}
	requestBody, err := cmpilookup.GenerateRequestBodyXml(params)

	if err != nil {
		fmt.Printf("Error generating request body XML: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Generated request body:")
	fmt.Println(requestBody)

	responseBody, responseHeaders, err := cmpilookup.PerformCmpiLookupRequest(requestBody)

	if err != nil {
		fmt.Printf("Error performing request: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Received response:\n")
	fmt.Println(responseHeaders)
	fmt.Println("\n" + responseBody)

	// ErrorNo=0 means no error occurred:
	if strings.Contains(responseBody, "<ErrorNo>0</ErrorNo>") {
		fmt.Println("\nSuccessful response!")
	} else {
		fmt.Println("\nUnsuccessful response!")
	}

	// Successful response body should look something like this:
	// <CardinalMPI><ErrorNo>0</ErrorNo><TransactionId>...</TransactionId><...</Payload><StepUpUrl>https://centinelapistag.cardinalcommerce.com/V2/Cruise/StepUp</StepUpUrl><ErrorDesc></ErrorDesc><Cavv></Cavv><PAResStatus>C</PAResStatus><Enrolled>Y</Enrolled><ACSTransactionId>...</ACSTransactionId><EciFlag>07</EciFlag><ACSUrl>...</ACSUrl><ThreeDSServerTransactionId>...</ThreeDSServerTransactionId><CardBin>400000</CardBin><CardBrand>VISA</CardBrand><DSTransactionId>...</DSTransactionId><ThreeDSVersion>2.1.0</ThreeDSVersion><OrderId>...</OrderId><ChallengeRequired>N</ChallengeRequired><SignatureVerification>Y</SignatureVerification></CardinalMPI>
}
