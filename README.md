# cardinal-commerce-poc

Quick proof-of-concept for Cardinal Commerce 3DS integration.

### Setup

Install ruby `2.7.2` ([rbenv recommnded](https://github.com/rbenv/rbenv))

Next, install dependencies with:

```
bundle install
```

Then run `cp .env-sample .env` and fill in the `.env` file with Cardinal API credentials.

### Usage

1. start mock API server with `./scripts/server.sh`
2. open up the frontend at http://localhost:4567

You can also run a local console with `./scripts/console.sh`

Finally, if you want to just test the `cmpi_lookup` request in a standalone script, you can run `bundle exec ruby scripts/cmpi_lookup_demo.rb`
