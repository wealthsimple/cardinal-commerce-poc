package cmpilookup

import (
	"io/ioutil"
	"testing"
)

func TestGenerateCmpiRequestSignatureWithValidInputs(t *testing.T) {
	// Sample values from https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/1619492942/Cardinal+cmpi+Messages#Generating-a-Signature-Value
	apiKey := "13f1fd1b-ab2d-4c1f-8e2c-ca61878f2a44"
	timestamp := "1485534293321"
	signature, err := GenerateCmpiRequestSignature(apiKey, timestamp)
	expectedSignature := "X5TupwjjpO9hg5qIHG2h9aMCekWiqbYkzPkXkPopFMw="
	if signature != expectedSignature || err != nil {
		t.Fatalf(`GenerateCmpiRequestSignature => %q, %v, want match for %q, nil`, signature, err, expectedSignature)
	}
}

func TestGenerateCmpiRequestSignatureWithInvalidApiKey(t *testing.T) {
	apiKey := ""
	timestamp := "1485534293321"
	_, err := GenerateCmpiRequestSignature(apiKey, timestamp)
	if err == nil {
		t.Fatal("GenerateCmpiRequestSignature should return error for empty apiKey")
	}
}

func TestGenerateCmpiRequestSignatureWithInvalidTimestamp(t *testing.T) {
	apiKey := "13f1fd1b-ab2d-4c1f-8e2c-ca61878f2a44"
	timestamp := "1609890356"
	_, err := GenerateCmpiRequestSignature(apiKey, timestamp)
	if err == nil {
		t.Fatal("GenerateCmpiRequestSignature should return error for invalid timestamp")
	}
}

func TestGetRequestTimestampWithBuffer(t *testing.T) {
	timestamp := GetRequestTimestampWithBuffer()
	if len(timestamp) != 13 {
		t.Fatal("Expected unix epoch timestamp in milliseconds (13 digits)")
	}
}

func TestGenerateCmpiRequestBodyXmlWithValidParams(t *testing.T) {
	params := CmpiRequestBodyParams{
		ApiId:            "api-id-123",
		OrgUnit:          "org-unit-123",
		RequestSignature: "X5TupwjjpO9hg5qIHG2h9aMCekWiqbYkzPkXkPopFMw=",
		Timestamp:        "1485534293321",
		CardNumber:       "4000000000001091",
		CardExpiryMonth:  "02",
		CardExpiryYear:   "2024",
		OrderAmount: "12345",
		OrderCurrencyCode: "840",
		OrderNumber: "ws_transaction-0001",
		OrderTransactionMode: "P",
		OrderTransactionType: "C",
	}
	requestBody, err := GenerateCmpiRequestBodyXml(params)
	expectedRequestBody, _ := ioutil.ReadFile("test-fixtures/cmpi_request_output.xml")
	if requestBody != string(expectedRequestBody) || err != nil {
		t.Fatalf(`GenerateCmpiRequestBodyXml => %q, %v, want match for %q, nil`, requestBody, err, expectedRequestBody)
	}
}
