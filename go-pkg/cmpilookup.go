package cmpilookup

import (
	"crypto/sha256"
	"encoding/base64"
	"errors"
)

// Given a Cardinal apiKey and unix timestamp, return a request signature for
// the cmpi_lookup request. Cardinal docs on generating this signature:
// https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/1619492942/Cardinal+cmpi+Messages#Generating-a-Signature-Value
func GenerateCmpiRequestSignature(apiKey string, timestamp string) (string, error) {
	if apiKey == "" || timestamp == "" {
		return "", errors.New("Must provide apiKey and timestamp")
	}
	if len(timestamp) != 13 {
		return "", errors.New("Must provider unix epoch timestamp in milliseconds")
	}

	hashContents := timestamp + apiKey
	hash := sha256.New()
	hash.Write([]byte(hashContents))
	signature := base64.StdEncoding.EncodeToString(hash.Sum(nil))

	return signature, nil
}
