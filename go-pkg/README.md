golang version of `cmpi_lookup` script, tested on **go v1.15.6**

Run the main script to execute a cmpi_lookup request with:
```
API_ID=... API_KEY=... ORG_UNIT_ID=... go run main.go
```
(you must add the values for the credentails provided by Cardinal)

Run unit tests with
```
cd cmpilookup
go test
```
