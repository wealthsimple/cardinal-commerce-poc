package cmpilookup

import (
	"bytes"
	"crypto/sha256"
	"encoding/base64"
	"errors"
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
func GenerateRequestSignature(apiKey string, timestamp string) (string, error) {
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

// Further documentation for request body params can be found at:
// https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/905478187/Lookup+Request+cmpi+lookup
type RequestBodyParams struct {
	// Cardinal API request metadata (provided by TabaPay)
	ApiId            string
	OrgUnit          string
	RequestSignature string
	RequestTimestamp string

	// Card details (provided by TabaPay based on AccountId)
	CardNumber      string
	CardExpiryMonth string `MM format (example: "01" = January)`
	CardExpiryYear  string `YYYY format`

	// Order details (provided by Wealthsimple)
	OrderAmount                  string `order amount in cents (12345 = $123.45)`
	OrderAuthenticationIndicator string `type of Authentication request (01 = Payment)`
	OrderCurrencyCode            string `3-digit ISO 3166-1 country code`
	OrderNumber                  string `unique id for order`
	OrderProductCode             string `PHY = physcial goods, ACF = account funding, ..`
	OrderTransactionMode         string `P = mobile, S = computer, T = tablet`
	OrderTransactionType         string `C = credit/debit`

	// Device details (provided by Wealthsimple)
	BrowserColorDepth        string
	BrowserHeader            string
	BrowserJavaEnabled       string
	BrowserJavascriptEnabled string
	BrowserLanguage          string
	BrowserScreenHeight      string
	BrowserScreenWidth       string
	BrowserTimeZone          string
	DeviceChannel            string
	DeviceReferenceId        string
	IpAddress                string
	UserAgent                string

	// Cardholder details (provided by Wealthsimple)
	BillingAddressStreet1     string
	BillingAddressStreet2     string
	BillingAddressCity        string
	BillingAddressPostalCode  string
	BillingAddressState       string `Country subdivision code in ISO 3166-2 format`
	BillingAddressCountryCode string
	BillingFirstName          string
	BillingMiddleName         string
	BillingLastName           string
	Email                     string
	MobilePhone               string `Phone unformatted without hyphens`
}

func GenerateRequestBodyXml(params RequestBodyParams) (string, error) {
	// Open up the XML template file via relative path:
	_, file, _, _ := runtime.Caller(0)
	relativePath := path.Join(path.Dir(file))
	xmlTemplate := template.Must(template.ParseFiles(relativePath + "/cmpi_request_body_template.xml"))

	// Interpolate params into template:
	requestBodyBuffer := bytes.Buffer{}
	xmlTemplate.Execute(io.Writer(&requestBodyBuffer), params)

	return requestBodyBuffer.String(), nil
}

func PerformCmpiLookupRequest(cmpiRequestBodyXml string) (string, map[string][]string, error) {
	response, err := http.PostForm(
		"https://centineltest.cardinalcommerce.com/maps/txns.asp",
		url.Values{"cmpi_msg": {cmpiRequestBodyXml}},
	)
	if err != nil {
		return "", nil, err
	}

	defer response.Body.Close()
	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return "", nil, err
	}

	// Remove excess whitespace at end of response:
	trimmedBody := strings.TrimRight(string(body), "\t \n")
	return trimmedBody, response.Header, nil
}
