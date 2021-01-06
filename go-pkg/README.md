golang version of `cmpi_lookup` script, tested on **go v1.15.6**

Run the main script to execute a cmpi_lookup request with the following (replace `...` with actual Cardinal Sandbox credentials):
```
API_ID=... API_KEY=... ORG_UNIT=... go run main.go
```

Run unit tests with
```
cd cmpilookup
go test
```
