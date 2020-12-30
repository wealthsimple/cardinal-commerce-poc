# cardinal-commerce-poc

Proof of concept for Cardinal Commerce 3DS integration.

### Setup

```
bundle install
```

Then run `cp .env-sample .env` and fill in the `.env` file with Cardinal API credentials ZIP file provided by Tharaneesan.

### Usage

1. start mock API server

```
bundle exec rerun 'ruby app.rb'
```

2. open up the frontend at http://localhost:4567
