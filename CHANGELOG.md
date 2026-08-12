# Changelog

All notable changes to `fragment-dev` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

Releases prior to `2.0.0` were published before this changelog was added and
are not documented here.

## [2.1.0]

### Added

- `add_ledger_entries` posts a batch of Ledger Entries atomically. It accepts
  raw `AddLedgerEntryInput` hashes, typed payloads, or both in one batch, and
  preserves their order.
- Strongly-typed batch payloads. `FragmentClient::TypedEntries.load` derives one
  payload class per `(Ledger Entry type, typeVersion)` from the per-entry-type
  `addLedgerEntry` operations the Fragment CLI generates for your Schema. Because a
  batch mutation takes one list of one input type, GraphQL cannot type each entry's
  `parameters` field individually; these payloads do. Payload names always carry the
  entry type version, defaulting to `V1`:

  ```ruby
  fragment.add_ledger_entries(entries: [
    FragmentClient::Entries::UserFundsAccountV1.new(
      ik: 'some-ik', ledger_ik: 'your-ledger-ik', user_id: 'user-1', funding_amount: '200'
    )
  ])
  ```

  Payloads are registered automatically from `extra_queries_filenames`. A field
  you did not set is omitted from the request rather than sent as `null`.
- Sorbet support, via three Tapioca DSL compilers. Run `bundle exec tapioca dsl`
  after loading your operations and Sorbet checks both the typed payloads and every
  query method -- `client.create_ledger(...)` previously reported `Method
  'create_ledger' does not exist`, because those methods are defined per instance.
  Response fields are typed too, from each operation's selection set and the
  Schema, so `client.get_ledger(...).data&.ledger&.name` is checked and reading a
  field the operation did not select is a type error rather than a runtime one.
  See the README's Sorbet section.
- `FragmentClient.load_queries`, which registers a `.graphql` document's operations
  and typed payloads without credentials, for use in an initializer.
- `bundle exec rake coverage`, writing `coverage/index.html`.
- `docs/spec-conformance.md`, mapping this SDK onto the shared
  `typed-batch-entries` specification section by section, with its deviations.

### Changed

- `lib/fragment.schema.json` refreshed. Adds `AddLedgerEntriesError` and
  `AddLedgerEntryError`, without which `addLedgerEntries` could not be parsed at
  all, plus `createPayment` and `Payment` from upstream.
- `oauth_url` and `oauth_scope` now treat an explicit `nil` as "use the default",
  where before it raised a `TypeError` from the type assertion in the constructor.
- An unusable `oauth_url` now raises `ArgumentError` from `FragmentClient.new`,
  naming the argument and its value. **This changes the exception class in two
  cases.** A non-HTTP URL previously failed later, inside the token request, as
  `NoMethodError: undefined method 'request_uri'`; a malformed one escaped as
  `URI::InvalidURIError`. Both were constructor-time failures on a misconfigured
  URL rather than handled paths, which is why this is a minor rather than a major
  release — but if you rescue `URI::InvalidURIError` around client construction,
  rescue `ArgumentError` instead.
- `lib/fragment_client.rb` typechecks under Sorbet (`# typed: true`), and `srb tc`
  runs in CI. The checked-in gem RBIs were several major versions stale and have
  been regenerated.

## [2.0.0]

### Changed

- `GetLedgerAccountBalance` now returns total `balance` (self + children) instead of `ownBalance`.
- `ListLedgerAccountBalances` and `ListMultiCurrencyLedgerAccountBalances` now accept `consistencyMode` on `childBalance`, `childBalances`, `balance`, and `balances`.

### Removed

- `GetLedgerAccountBalanceWithChildRollup` has been removed.

### Upgrade Guide

1.  **Upgrade your schema to use the total balance consistency feature:**

    1.  Add the path to your schema JSON or the JSON itself to the top of the prompt below and give it to your LLM of choice. It'll make some small changes to your consistency configs and conditions.
    2.  Deploy the new schema
```
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

2.  **Upgrade your Fragment SDK to the latest version:**

    1.  `GetLedgerAccountBalance` now returns total `balance` (self + children) instead of `ownBalance`.
        1.  Change `$ownBalanceConsistencyMode` to `$balanceConsistencyMode`
    2.  Use `GetLedgerAccountBalance` instead of `GetLedgerAccountBalanceWithChildRollup`.