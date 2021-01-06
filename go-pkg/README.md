Golang implementation of [Caridnal `cmpi_lookup`](https://cardinaldocs.atlassian.net/wiki/spaces/CCen/pages/1619492942/Cardinal+cmpi+Messages), tested on **go v1.15.6**.

Run the main script to execute a cmpi_lookup request with the following (replace `...` with actual Cardinal Sandbox credentials):
```
API_ID=... API_KEY=... ORG_UNIT=... go run main.go
```

Run unit tests with:
```
cd cmpilookup
go test
```
