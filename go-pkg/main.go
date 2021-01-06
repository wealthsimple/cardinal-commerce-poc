// Sample usage:
// API_KEY=... go run main.go

package main

import (
	"./cmpilookup"
	"fmt"
	"os"
)

func main () {
	fmt.Println("Running cmpi_lookup request...")

	timestamp := cmpilookup.GetRequestTimestampWithBuffer()
	fmt.Println(timestamp)

	signature, err := cmpilookup.GenerateCmpiRequestSignature(os.Getenv("API_KEY"), timestamp)

	if (err != nil) {
		fmt.Printf("Error generating request signature: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Generated request signature: %q\n", signature);
}
