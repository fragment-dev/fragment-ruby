# Changelog

All notable changes to `fragment-dev` are documented in this file. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Version numbers
follow [Semantic Versioning](https://semver.org/). Releases before `2.0.0`
predate this changelog and are not documented here.

## [2.4.1]

### Added

- `createPayment` accepts an optional `paymentMethod`. When it is set, the
  Payment is charged to that saved Payment Method immediately.
- `createPaymentMethodSetup` to save a Payment Method for a user. It takes
  an `ik`, a `ledgerIk` and the user's `email`. It returns the Payment Method
  Setup's `clientSecret`, `status` and `paymentMethod`.
- `getPaymentMethodSetup` to retrieve a Payment Method Setup.
- `listPaymentMethods` to list a user's saved Payment Methods on a Ledger. It takes
  an `email`, a `ledgerIk` and optional pagination.
- `getPaymentMethod` to fetch a saved Payment Method by its `id`.
  `deletePaymentMethod` to delete a saved Payment Method by `id`.
- `syncCustomAccountsByLinkIk` and `syncCustomTxsByLinkIk` to sync Custom Link
  Accounts and Transactions using the Custom Link's `ik`.

### Changed

- `lib/fragment.schema.json` is refreshed. It no longer marks Payments as
  experimental. It adds `reconciliationReport` on `Ledger`, which no bundled
  query uses yet.

## [2.4.0]

### Added

- `createPayment` also returns the Payment's `id`, `ik`, `amount`, `mode` and
  `currency`. You can pass its `payment` to `<PaymentSession>` in
  `@fragment-dev/payment-elements` unchanged.
- `LedgerLinesFilterSet` accepts `externalTxIds`. It filters Ledger Lines by the
  external IDs of their linked transactions.

### Changed

- `PaymentStatus` uses `accepted` in place of `approved`. Payments are
  experimental, so this API may change in a future release.

## [2.3.0]

### Added

- `getPayment` fetches a Payment on a Ledger by `ik` and `ledgerIk`. It returns
  the Payment's `amount`, `currency`, `status`, `type`, `typeVersion`, `mode`,
  `parameters` and `created` time.
- `listPayments` lists the Payments on a Ledger. It takes a `ledgerIk`, optional
  pagination (`first`, `after`, `before`) and an optional `filter`.
- `instantiateLedgerAccount` creates a Ledger Account from a Schema template. It
  takes a `ledger`, a template `path` and optional `parameters`.

### Changed

- `createPayment` requires `typeVersion`.
- `createPayment` nests the Payment in its response. Read `clientSecret` and
  `status` from the `payment` field instead of the top level. Payments are
  experimental, so this API may change in a future release.

## [2.2.0]

### Added

- `createPayment` creates a Payment on a Ledger. It takes an `ik`, a `ledgerIk`,
  a Payment `type` and optional `typeVersion` and `parameters`. It returns the
  Payment's `clientSecret` and `status`. Payments are experimental, so this API
  may change in a future release.

### Changed

- `LedgerEntryInput` supports `typeVersion`, which defaults to `1`. Earlier
  releases reserved the field for an upcoming feature.
- `PaymentStatus` uses `needs_payment_method` in place of
  `requires_confirmation`.
- `SchemaPaymentEntryStatus` is renamed to `SchemaPaymentTypeStatus`.
- `SchemaPaymentEntryInput` takes `needs_payment_method_to_processing` in place
  of `needs_confirmation_to_processing`.

## [2.1.0]

### Added

#### Batch Ledger Entries

`add_ledger_entries` posts a batch of Ledger Entries atomically, in the order you
pass them. A batch can hold raw `AddLedgerEntryInput` hashes, typed payloads or
both. `FragmentClient::TypedEntries.load` derives one typed payload class per
Ledger Entry type and `typeVersion`. Every payload name carries the version,
which defaults to `V1`:

```ruby
fragment.add_ledger_entries(entries: [
  FragmentClient::Entries::UserFundsAccountV1.new(
    ik: 'some-ik', ledger_ik: 'your-ledger-ik', user_id: 'user-1', funding_amount: '200'
  )
])
```

- `TypedEntries.load` reads the per-entry-type `addLedgerEntry` operations that
  the Fragment CLI generates for your Schema.
- A batch mutation takes one list of one input type. GraphQL cannot type the
  `parameters` of each entry, so the payloads type them.
- The client registers payloads from `extra_queries_filenames` automatically.
- A field you did not set is left out of the request. The payload never sends
  it as `null`.
- `FragmentClient.load_queries` registers the operations and typed payloads of a
  `.graphql` document without credentials. Call it in an initializer.

#### Sorbet

Three Tapioca DSL compilers add Sorbet support. Run `bundle exec tapioca dsl`
after you load your operations. Sorbet then checks the typed payloads and every
query method. The client defines query methods per instance, so earlier releases
reported `Method 'create_ledger' does not exist`. Response fields get types from
each operation's selection set and the Schema. Sorbet reports a read of a field
that the operation did not select:

```ruby
# Sorbet checks each step against the GetLedger selection set.
client.get_ledger(...).data&.ledger&.name
```

The README's Sorbet section covers the setup.

#### Tooling

- `bundle exec rake coverage` writes `coverage/index.html`.
- `docs/spec-conformance.md` maps this SDK onto the shared `typed-batch-entries`
  specification, section by section. It lists where the SDK deviates.

### Changed

- `lib/fragment.schema.json` is refreshed. It adds `AddLedgerEntriesError` and
  `AddLedgerEntryError`, which the client needs to parse `addLedgerEntries`. It
  also adds `createPayment` and `Payment` from upstream.
- `oauth_url` and `oauth_scope` treat an explicit `nil` as "use the default".
  Earlier releases raised a `TypeError` from the constructor's type assertion.
- An unusable `oauth_url` raises `ArgumentError` from `FragmentClient.new`. The
  message names the argument and its value.
- `lib/fragment_client.rb` typechecks under Sorbet with `# typed: true`. CI runs
  `srb tc`. The checked-in gem RBIs were several major versions stale, and this
  release regenerates them.

> [!NOTE]
> The `oauth_url` change alters the exception class in two cases. A non-HTTP URL
> used to fail later, in the token request, as
> `NoMethodError: undefined method 'request_uri'`. A malformed URL raised
> `URI::InvalidURIError`. Both were construction failures on a misconfigured URL,
> so this ships as a minor release. If you rescue `URI::InvalidURIError` around
> client construction, rescue `ArgumentError` instead.

## [2.0.0]

### Changed

- `GetLedgerAccountBalance` returns the total `balance` of the Ledger Account and
  its children. It no longer returns `ownBalance`.
- `ListLedgerAccountBalances` and `ListMultiCurrencyLedgerAccountBalances` accept
  `consistencyMode` on `childBalance`, `childBalances`, `balance` and `balances`.

### Removed

- `GetLedgerAccountBalanceWithChildRollup` is removed. Use
  `GetLedgerAccountBalance` instead.

### Upgrade Guide

1. Give the prompt below to an LLM, with your Schema JSON or its path at the top.
   It moves your consistency configs and entry conditions to total balances.
2. Deploy the updated Schema.
3. Upgrade the Fragment SDK to `2.0.0` or later.
4. In `GetLedgerAccountBalance` calls, rename `$ownBalanceConsistencyMode` to
   `$balanceConsistencyMode`.
5. Replace each `GetLedgerAccountBalanceWithChildRollup` call with
   `GetLedgerAccountBalance`.

The prompt for step 1 replaces `<YOUR_SCHEMA_OR_PATH>` with your Schema:

```text
Fragment schema JSON path or full schema: <YOUR_SCHEMA_OR_PATH>

Above is a Fragment schema JSON file or the path to it. Transform it to use total balances by following
the rules below, then validate the result. If a file path is provided, edit the file in place — do not
create a copy or temporary file.

Rules

1. Entry conditions

Replace ownBalance with totalBalance in all entry conditions.

2. Default consistency config

In the schema's defaultConsistencyConfig, replace ownBalanceUpdates with totalBalanceUpdates.

3. Ledger account consistency config

For each ledger account (not groups — groups keep ownBalanceUpdates unchanged), determine the new
consistency value using these three questions:

- (A) Is this account a leaf on any entry line? Check whether any entry in the schema references this
account as a line target.
- (B) Is this account strongly consistent? Either it has an explicit ownBalanceUpdates: "strong", or it
inherits "strong" from defaultConsistencyConfig.
- (C) Does this account have an entry condition? Check whether any entry condition references this
account.

Then apply:

- (A) Yes + (B) Yes           → totalBalanceUpdates: "strong"
- (C) Yes                      → totalBalanceUpdates: "strong"
- (A) No  + (B) Yes + (C) No  → totalBalanceUpdates: "eventual"
- (B) No  + (C) No            → totalBalanceUpdates: "eventual"

In short: an account gets totalBalanceUpdates: "strong" if it is either a leaf on an entry line and was
already strongly consistent, or has an entry condition. Everything else becomes "eventual".

4. Groups are excluded

Do not change ownBalanceUpdates on groups. This migration only applies to ledger accounts.

Pre-Validation

Validate the transformed schema before returning it:

- If the input was a file path, run: fragment verify-schema --path <path-to-schema> --verbose
- If the input was pasted schema JSON, write it to a temporary file and run: fragment verify-schema --path
<temp-file> --verbose
- If you don't have access to a shell, skip this step.
```
