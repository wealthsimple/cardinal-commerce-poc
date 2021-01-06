package cmpilookup

import (
	"bytes"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"io"
	"strconv"
	"text/template"
	"time"
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

// Returns the unix epoch timestamp in milliseconds (with small buffer)
// Jason Chow from Cardinal recommended the small buffer since otherwise the
// cmpi_lookup request will sporadically fail.
func GetRequestTimestampWithBuffer() (string) {
	timestampBuffer := int64(10000)
	timestampInMilliseconds := time.Now().UnixNano() / int64(time.Millisecond)
	return strconv.FormatInt(timestampInMilliseconds - timestampBuffer, 10)
}

// TODO: add all remaining params here:
type CmpiRequestBodyParams struct {
	// API request metadata
	ApiId            string
	OrgUnit          string
	RequestSignature string
	Timestamp        string
	// Card details
	CardNumber      string
	CardExpiryMonth string
	CardExpiryYear  string
}

func GenerateCmpiRequestBodyXml(params CmpiRequestBodyParams) (string, error) {
	xmlTemplate := template.Must(template.ParseFiles("cmpi_request_body_template.xml"))

	requestBodyBuffer := bytes.Buffer{}
	xmlTemplate.Execute(io.Writer(&requestBodyBuffer), params)

	return requestBodyBuffer.String(), nil
}
