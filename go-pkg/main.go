// Sample usage:
// API_KEY=... go run main.go

package main

import (
	"./cmpilookup"
	"fmt"
	"os"
)

func main() {
	fmt.Println("Running cmpi_lookup request...")

	timestamp := cmpilookup.GetRequestTimestampWithBuffer()
	fmt.Printf("Generated request timestamp: %q\n", timestamp)

	signature, err := cmpilookup.GenerateCmpiRequestSignature(os.Getenv("API_KEY"), timestamp)

	if err != nil {
		fmt.Printf("Error generating request signature: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Generated request signature: %q\n", signature)

	params := cmpilookup.CmpiRequestBodyParams{
		ApiId:            os.Getenv("API_ID"),
		OrgUnit:          os.Getenv("ORG_UNIT"),
		RequestSignature: signature,
		Timestamp:        timestamp,
		// Wealthsimple will provide TabaPay an AccountId, from which TabaPay can
		// extract the below card details.
		// Cardinal Sandbox card PANs can be found at https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/903577725/EMV+3DS+Test+Cases
		CardNumber:      "4000000000001091",
		CardExpiryMonth: "02",
		CardExpiryYear:  "2024",
	}
	requestBody, err := cmpilookup.GenerateCmpiRequestBodyXml(params)
	if err != nil {
		fmt.Printf("Error generating request body XML: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Generated request body:")
	fmt.Println(requestBody)

	response, err := cmpilookup.PerformCmpiLookupRequest(requestBody)
	if err != nil {
		fmt.Printf("Error performing request: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("Received response:")
	fmt.Println(response)
}
