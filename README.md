# `fragment-ruby-sdk`

[Fragment](https://fragment.dev) is the Ledger API for engineers that move money. Stop wrangling payment tables, debugging balance errors and hacking together data pipelines. Start shipping the features that make a difference.

## Installation

To install the Fragment SDK for Ruby, you'll need to install the gem. Run the following command in your terminal:

```bash
gem install fragment-dev
```

Or if you are using bundler add `gem fragment-dev` to your Gemfile.

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

### Post a batch of Ledger Entries

`add_ledger_entries` commits a batch atomically — either every entry commits or
none do. Idempotency keys are per entry, so a retried batch reports `isIkReplay`
for each one.

```ruby
result = fragment.add_ledger_entries(entries: [
  {
    ik: "some-ik",
    entry: {
      ledger: { ik: "your-ledger-ik" },
      type: "user_funds_account",
      posted: "1968-01-01T16:45:00Z",
      parameters: { user_id: "user-1", funding_amount: "200" }
    }
  }
])

case result.data.add_ledger_entries.__typename
when "AddLedgerEntriesResult"
  result.data.add_ledger_entries.results.each { |r| puts [r.entry.ik, r.is_ik_replay].inspect }
when "AddLedgerEntriesError"
  # One element per failing entry, each carrying the ik that identifies it.
  result.data.add_ledger_entries.errors.each { |e| warn "#{e.ik}: #{e.message}" }
end
```

Writing those nested hashes by hand is easy to get wrong, and nothing checks the
parameter names against your Schema. The next section is about not doing that.

### Typed batch payloads

The Fragment CLI generates a per-entry-type `addLedgerEntry` operation for each
Ledger Entry in your Schema. Those operations know two things GraphQL cannot
express for a batch: the entry type, and the type of every parameter. The SDK
derives a payload class per Ledger Entry from them.

Pass the `.graphql` file as an extra queries file and the payloads are registered
for you:

```ruby
fragment = FragmentClient.new(
  'your-client-id',
  'your-client-secret',
  extra_queries_filenames: ['app/graphql/entries.graphql']
)

fragment.add_ledger_entries(entries: [
  FragmentClient::Entries::UserFundsAccountV1.new(
    ik: "some-ik",
    ledger_ik: "your-ledger-ik",
    posted: "1968-01-01T16:45:00Z",
    user_id: "user-1",
    funding_amount: "200"
  )
])
```

A payload is named for its Ledger Entry type and the version it posts, so adding
`user_funds_account` v2 later leaves every existing `...V1` call site alone. A
misspelled or missing parameter raises immediately rather than reaching the API,
and typed payloads can be mixed with the raw hashes above in a single batch.

Nothing you did not set is sent. An omitted field is absent from the request; an
explicit `nil` is sent as `null`, because those mean different things to the API.

Readers behave the way you would expect either way — an unset field reads as `nil`,
so `entry.posted&.iso8601` and `if entry.description` do the obvious thing. When
you need to tell "never set" from "set to `nil`", ask:

```ruby
entry = FragmentClient::Entries::UserFundsAccountV1.new(
  ik: "some-ik", ledger_ik: "your-ledger-ik", user_id: "user-1", funding_amount: "200"
)
entry.posted           #=> nil
entry.set?(:posted)    #=> false

entry.to_entry_input   # the exact hash that goes on the wire, if you want to inspect it
```

Payloads compare by value, so they are straightforward to assert on in your own
tests.

You can register payloads without constructing a client — no credentials, no
network:

```ruby
FragmentClient::TypedEntries.load('app/graphql/entries.graphql')
FragmentClient::TypedEntries.fetch('user_funds_account', 1)
#=> FragmentClient::Entries::UserFundsAccountV1
```

### Sorbet

The gem ships a [Tapioca](https://github.com/Shopify/tapioca) DSL compiler, so
Sorbet can typecheck the payloads even though they are built at load time. Put a
`TypedEntries.load` call somewhere Tapioca loads — a Rails initializer, or
`sorbet/tapioca/require.rb` — then:

```bash
bundle exec tapioca dsl
```

That writes an RBI giving each payload a real signature. `srb tc` will then reject
a wrong parameter type, a missing required parameter, and a parameter your Schema
does not declare.

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

1. Define your custom GraphQL queries in a `.graphql` file. For example, in `extra.graphql`.

2. When creating the client, pass the `extra_queries_filenames` parameter to specify the paths to your custom GraphQL file:

```ruby
fragment = FragmentClient.new(
  'your-client-id',
  'your-client-secret',
  api_url: 'api url from dashboard',
  oauth_url: 'auth url from dashboard',
  oauth_scope: 'scope from dashboard',
  extra_queries_filenames: ['path/to/your/extra.graphql']
)
```

This setup allows you to enhance your SDK usage with tailored queries, ensuring you can handle all your business-specific cases effectively.

## Development

Requires Ruby >= 3.2, as the gemspec says; CI covers 3.2, 3.3 and 3.4.

```bash
bundle install
bundle exec rake       # the default task
bundle exec rake -T    # everything else
```

If your locale is not UTF-8, set one. `GraphQL::Client.load_schema` reads
`lib/fragment.schema.json`, which carries non-ASCII currency names, and raises
`invalid byte sequence in US-ASCII` under a US-ASCII default external encoding.

`docs/spec-conformance.md` maps this SDK onto the shared typed-batch-entries
specification, and records where it deviates and why.
