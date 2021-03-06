package cmpilookup

import (
	"io/ioutil"
	"testing"
)

func TestGenerateRequestSignatureWithValidInputs(t *testing.T) {
	// Sample values from https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/1619492942/Cardinal+cmpi+Messages#Generating-a-Signature-Value
	apiKey := "13f1fd1b-ab2d-4c1f-8e2c-ca61878f2a44"
	timestamp := "1485534293321"
	signature, err := GenerateRequestSignature(apiKey, timestamp)
	expectedSignature := "X5TupwjjpO9hg5qIHG2h9aMCekWiqbYkzPkXkPopFMw="
	if signature != expectedSignature || err != nil {
		t.Fatalf(`GenerateRequestSignature => %q, %v, want match for %q, nil`, signature, err, expectedSignature)
	}
}

func TestGenerateRequestSignatureWithInvalidApiKey(t *testing.T) {
	apiKey := ""
	timestamp := "1485534293321"
	_, err := GenerateRequestSignature(apiKey, timestamp)
	if err == nil {
		t.Fatal("GenerateRequestSignature should return error for empty apiKey")
	}
}

func TestGenerateRequestSignatureWithInvalidTimestamp(t *testing.T) {
	apiKey := "13f1fd1b-ab2d-4c1f-8e2c-ca61878f2a44"
	timestamp := "1609890356"
	_, err := GenerateRequestSignature(apiKey, timestamp)
	if err == nil {
		t.Fatal("GenerateRequestSignature should return error for invalid timestamp")
	}
}

func TestGetRequestTimestampWithBuffer(t *testing.T) {
	timestamp := GetRequestTimestampWithBuffer()
	if len(timestamp) != 13 {
		t.Fatal("Expected unix epoch timestamp in milliseconds (13 digits)")
	}
}

func TestGenerateRequestBodyXmlWithValidParams(t *testing.T) {
	params := RequestBodyParams{
		ApiId:                        "api-id-123",
		OrgUnit:                      "org-unit-123",
		RequestSignature:             "X5TupwjjpO9hg5qIHG2h9aMCekWiqbYkzPkXkPopFMw=",
		RequestTimestamp:             "1485534293321",
		CardNumber:                   "4000000000001091",
		CardExpiryMonth:              "02",
		CardExpiryYear:               "2024",
		OrderAmount:                  "12345",
		OrderAuthenticationIndicator: "01",
		OrderCurrencyCode:            "840",
		OrderNumber:                  "ws_transaction-0001",
		OrderProductCode:             "ACF",
		OrderTransactionMode:         "P",
		OrderTransactionType:         "C",
		BrowserColorDepth:            "32",
		BrowserHeader:                "text/html,application/xhtml+xml,application/xml;q=0.9,",
		BrowserJavaEnabled:           "true",
		BrowserJavascriptEnabled:     "true",
		BrowserLanguage:              "en-CA",
		BrowserScreenHeight:          "980",
		BrowserScreenWidth:           "1080",
		BrowserTimeZone:              "200",
		DeviceChannel:                "browser",
		DeviceReferenceId:            "c17dea31-9cf6-0c1b8f2d3c5",
		IpAddress:                    "67.17.219.20",
		UserAgent:                    "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:30.0) Gecko/20100101 Firefox/30.0",
		BillingAddressStreet1:        "4 Jersey St",
		BillingAddressStreet2:        "Unit 123",
		BillingAddressCity:           "Boston",
		BillingAddressPostalCode:     "02215",
		BillingAddressState:          "MA",
		BillingAddressCountryCode:    "840",
		BillingFirstName:             "Pedro",
		BillingLastName:              "Martinez",
		BillingMiddleName:            "Jaime",
		Email:                        "cardinal.mobile.test@example.com",
		MobilePhone:                  "+16175551234",
	}
	requestBody, err := GenerateRequestBodyXml(params)
	expectedRequestBody, _ := ioutil.ReadFile("test-fixtures/cmpi_request_output.xml")
	if requestBody != string(expectedRequestBody) || err != nil {
		t.Fatalf(`GenerateRequestBodyXml => %q, %v, want match for %q, nil`, requestBody, err, expectedRequestBody)
	}
}
