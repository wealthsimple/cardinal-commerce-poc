package cmpilookup

import (
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
