package cmpilookup

import (
	"bytes"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"
	"path"
	"runtime"
	"strconv"
	"strings"
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
func GetRequestTimestampWithBuffer() string {
	timestampBuffer := int64(10000)
	timestampInMilliseconds := time.Now().UnixNano() / int64(time.Millisecond)
	return strconv.FormatInt(timestampInMilliseconds-timestampBuffer, 10)
}

// TODO: add all remaining params here:
type CmpiRequestBodyParams struct {
	// Cardinal API request metadata (provided by TabaPay)
	ApiId            string
	OrgUnit          string
	RequestSignature string
	Timestamp        string

	// Card details (provided by TabaPay based on AccountId)
	CardNumber      string
	CardExpiryMonth string
	CardExpiryYear  string

	// Order details (provided by Wealthsimple)
	OrderAmount string
	OrderCurrencyCode string
	OrderNumber string
	OrderTransactionMode string
	OrderTransactionType string
}

func GenerateCmpiRequestBodyXml(params CmpiRequestBodyParams) (string, error) {
	// Open up the XML template file via relative path:
	_, file, _, _ := runtime.Caller(0)
	relativePath := path.Join(path.Dir(file))
	xmlTemplate := template.Must(template.ParseFiles(relativePath + "/cmpi_request_body_template.xml"))

	// Interpolate params into template:
	requestBodyBuffer := bytes.Buffer{}
	xmlTemplate.Execute(io.Writer(&requestBodyBuffer), params)

	return requestBodyBuffer.String(), nil
}

func PerformCmpiLookupRequest(cmpiRequestBodyXml string) (string, error) {
	response, err := http.PostForm(
		"https://centineltest.cardinalcommerce.com/maps/txns.asp",
		url.Values{"cmpi_msg": {cmpiRequestBodyXml}},
	)
	if err != nil {
		return "", err
	}

	defer response.Body.Close()
	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return "", err
	}
	trimmedBody := strings.TrimRight(string(body), "\t \n")

	if strings.Contains(trimmedBody, "Error Processing Lookup Request Message") {
		return "", errors.New(fmt.Sprintf("Unsuccessful response: %q", trimmedBody))
	}

	return trimmedBody, nil
}