package cmpilookup

import (
	"bytes"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"io"
	"text/template"
)

// Given a Cardinal apiKey and unix timestamp, return a request signature for
// the cmpi_lookup request. Cardinal docs on generating this signature:
// https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/1619492942/Cardinal+cmpi+Messages#Generating-a-Signature-Value
func GenerateCmpiRequestSignature(apiKey string, timestamp string) (string, error) {
	if apiKey == "" || timestamp == "" {
		return "", errors.New("Must provide apiKey and timestamp")
	}
	if len(timestamp) != 13 {
		return "", errors.New("Must provide unix epoch timestamp in milliseconds")
	}

	hashContents := timestamp + apiKey
	hash := sha256.New()
	hash.Write([]byte(hashContents))
	signature := base64.StdEncoding.EncodeToString(hash.Sum(nil))

	return signature, nil
}

// TODO: add all remaining params here:
type CmpiRequestBodyParams struct {
	ApiId            string
	OrgUnit          string
	RequestSignature string
	Timestamp        string
}

func GenerateCmpiRequestBodyXml(params CmpiRequestBodyParams) (string, error) {
	xmlTemplate := template.Must(template.ParseFiles("cmpi_request_body_template.xml"))

	requestBodyBuffer := bytes.Buffer{}
	xmlTemplate.Execute(io.Writer(&requestBodyBuffer), params)

	return requestBodyBuffer.String(), nil
}
