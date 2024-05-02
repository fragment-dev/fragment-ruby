# `fragment-ruby-sdk`

[Fragment](https://fragment.dev) is the Ledger API for engineers that move money. Stop wrangling payment tables, debugging balance errors and hacking together data pipelines. Start shipping the features that make a difference.

## Installation

To install the Fragment SDK for Ruby, you'll need to build and install the gem. Run the following commands in your terminal:

```bash
bundle exec gem build fragment-alpha-sdk.gemspec
bundle exec gem install ./fragment-alpha-sdk-0.1.7.gem
bundle install
```

## Usage

To use the Fragment SDK in your Ruby application, first require the library:

```ruby
require 'fragment_client'
```

Then instantiate a client by calling `FragmentClient.new` with the necessary credentials. You can generate credentials using the Fragment [dashboard](https://dashboard.fragment.dev/go/s/api-clients).

```ruby
fragment = FragmentClient.new(
  'your-client-id',
  'your-client-secret',
  api_url: 'api url from dashboard',
  oauth_url: 'auth url from dashboard',
  oauth_scope: 'scope from dashboard'
)
```

### Post a Ledger Entry

To post a Ledger Entry defined in your schema:

```ruby
fragment.add_ledger_entry({
  ik: "some-ik",
  ledgerIk: "your-ledger-ik",
  type: "user_funds_account",
  posted: "1968-01-01T16:45:00Z",
  parameters: {
    user_id: "user-1",
    funding_amount: "200",
  }
})
```

### Sync Transactions

To sync transaction using a custom link:

```ruby
fragment.sync_custom_accounts({
  linkId: "custom-link-id",
  accounts: [
    {
      externalId: "operating-account",
      name: "Operating Bank Account",
      currency: {
        code: "USD",
      },
    },
  ]
})

fragment.sync_custom_txs({
  linkId: "custom-link-id",
  txs: [
    {
      externalId: "tx-123",
      description: "Test user funding",
      account: {
        externalId: "operating-account",
        linkId: "custom-link-id",
      },
      amount: "100",
      currency: {
        code: "USD",
      },
      posted: "1968-01-01",
    },
  ]
})
```

### Reconcile a Transaction

To reconcile a transaction:

```ruby
fragment.reconcile_tx({
  ledgerIk: "your-ledger-ik",
  type: "funding_settlement",
  parameters: {
    user_id: "user-1",
    net_amount: "99",
    fee_amount: "1",
    link_id: "stripe",
    link_account_id: "stripe-balance",
    link_tx_id: "tx_456",
  }
})
```

### Get a Schema

To retrieve a schema by its key and access the specific fields:

```ruby
schema_response = fragment.get_schema({
  key: "schemaKey",
})
schema_key = schema_response.data.schema.key  # Assuming this remains in camelCase if it's a direct API response attribute
```

### Get a Ledger

To retrieve a ledger and access its details:

```ruby
ledger_response = fragment.get_ledger({
  ik: "your-ledger-ik",
})
ledger_details = ledger_response.data.ledger
```

### Get a Ledger Entry

To fetch a specific ledger entry and access its data:

```ruby
ledger_entry_response = fragment.get_ledger_entry({
  ik: "card_swipe_a",
  ledgerIk: "your-ledger-ik",
})
ledger_entry_details = ledger_entry_response.data.ledger_entry
```

### Get a Ledger Account with Balance

To get the balance details of a specific ledger account:

```ruby
ledger_account_balance_response = fragment.get_ledger_account_balance({
  ledgerIk: "your-ledger-ik",
  path: "assets/receivables/user:user-1",
})
account_balance = ledger_account_balance_response.data.ledger_account
```

### List Ledger Accounts

To list all ledger accounts in a specific ledger and access the results:

```ruby
result = fragment.list_ledger_accounts({
  ledgerIk: "your-ledger-ik",
})
ledger_accounts = result.data.ledger.ledger_accounts
```


### Using Custom Queries

While the SDK comes with GraphQL queries out of the box, you may want to customize these queries for your product. To do that:

1. Define your custom GraphQL queries in a `.graphql` file, for example, in `extra.graphql`.

2. When creating the client, pass the `extra_queries_filename` parameter to specify the path to your custom GraphQL file:

```ruby
fragment = FragmentClient.new(
  'your-client-id',
  'your-client-secret',
  api_url: 'api url from dashboard',
  oauth_url: 'auth url from dashboard',
  oauth_scope: 'scope from dashboard',
  extra_queries_filename: 'path/to/your/extra.graphql'
)
```

This setup allows you to enhance your SDK usage with tailored queries, ensuring you can handle all your business-specific cases effectively.
