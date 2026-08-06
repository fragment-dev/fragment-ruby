# Typed batch Ledger Entries — Ruby conformance

How this SDK implements [`shared-spec/typed-batch-entries.md`][spec] in
`fragment-dev/graphql-queries`, section by section, plus the places it deviates
and why.

Spec version implemented: **0.1.0** (`test/spec/VERSION`).

Section numbers here are the spec's, and the spec appends rather than renumbers,
so they stay valid.

---

## The Ruby shape of it

The spec leaves the API shape to each SDK, and constrains only what goes on the
wire and what is derived from what. Two decisions follow from Ruby rather than
from the spec:

**No code generation.** Python, Node and Go generate source. Ruby libraries
generally do not, and a codegen step would be the strangest part of this SDK to a
Ruby caller — so the payload classes are built at load time, by
`FragmentClient::TypedEntries.load`, the same way ActiveRecord builds attribute
methods. `Class.new(TypedLedgerEntry)` per `(type, typeVersion)`, one keyword
argument and one reader per Schema parameter.

**Sorbet learns about them from Tapioca.** Load-time classes are invisible to a
static typechecker, and this is the problem Tapioca's DSL compilers exist for.
The gem ships one at `lib/tapioca/dsl/compilers/fragment_typed_entries.rb`;
`bundle exec tapioca dsl` writes an RBI giving each payload a real `initialize`
signature and typed readers. Runtime validation covers what Sorbet cannot see —
an untyped caller, or one who did not run Tapioca — but it is deliberately
limited to presence and unknown names. Parameter *types* are the RBI's job, and
duplicating them at runtime would mean guessing at custom scalars and rejecting
calls the API accepts.

`TypedEntries.load` therefore needs no credentials and makes no network calls: it
has to be callable from an initializer for `tapioca dsl` to see anything.

**The sentinel does not reach callers.** §3.2 needs three states — a value, an
explicit `null`, and never-set — and Ruby's `nil` default only expresses two, so
optional keywords default to an internal `UNSET` sentinel. It is converted at the
door: readers return `nil` for an unset field and `#set?` reports the difference.
Returning the sentinel would have made `if entry.posted` truthy and
`entry.fee&.upcase` raise, which is a trap for the majority of Ruby callers, who do
not run Sorbet and have no reason to know the sentinel exists. It also keeps the
generated signatures readable: `T.nilable(::String)` rather than a three-way union
on every optional field.

---

## Section by section

| § | Requirement | How | Verified by |
| --- | --- | --- | --- |
| 2.1 | Recognition: mutation, named, single `addLedgerEntry` selection, inline `entry`, literal `type` | `TypedEntries.entry_argument`, one guard per condition | `001-basic`; `typed_entries_test.rb` covers all six negatives |
| 2.1 | Non-qualifying operations skipped silently | Guards return `nil`; nothing logged | `test_non_qualifying_operations_are_skipped_silently` asserts no output |
| 2.1 | The SDK's own operations excluded | Falls out of the literal-`type` rule | `test_the_sdks_own_operations_yield_no_typed_payloads`, over the real `lib/queries.graphql` |
| 2.1 | Operation name irrelevant | Name is used only for warnings and the pathological collision case | `test_operation_name_is_irrelevant` |
| 2.2 | Identity is `(type, typeVersion)` | `EntrySpec#identity`; registry keyed on it | `002-type-versions`; `test_identity_is_the_pair_not_the_type` |
| 2.2 | Deduplicate; first in input order wins | `extract` uses a hash keyed on identity | `test_two_operations_with_one_identity_are_deduplicated` |
| 2.2 | May error on differing parameter sets | Warns instead, and keeps the first | `test_conflicting_parameter_sets_for_one_identity_warn_and_keep_the_first` |
| 2.3 | Only variable-bound fields become parameters | `extract_parameters` skips non-`VariableIdentifier` values | `test_a_parameter_fixed_by_the_operation_is_not_caller_supplied` |
| 2.3 | Type and required-ness from the variable definition | `variable_types`; `NonNullType` means required | `test_requiredness_comes_from_the_variable_not_the_parameter_name` |
| 2.3 | Payload still emitted without typed parameters | `parameters` falls back to an empty hash | `test_a_payload_is_still_derived_without_typed_parameters` |
| 2.3a | All seven common fields exposed | `TypedLedgerEntry::COMMON_FIELDS`, fixed by `LedgerEntryInput` | `test_every_common_field_reaches_the_wire` |
| 2.3a | `lines`, `type`, `typeVersion`, `parameters` not caller-supplied | Not declared; unknown keywords rejected | `test_lines_is_not_exposed`; `type_check_test.rb` rejects them statically |
| 2.4 | Parameters keep source order | `spec.parameters` is never re-sorted | `004-param-order`; and the strict-profile byte comparison, which is the assertion that actually catches a re-sort |
| 2.5 | Name always carries the resolved version | `EntrySpec#class_name` is `<Type>V<n>` | `test_an_unpinned_version_is_normalised_to_one_in_the_name_and_on_the_wire` |
| 2.5 | Name depends only on its own identity | Derived from `(type, version)`, nothing else | `test_a_name_does_not_depend_on_which_other_operations_are_loaded` |
| 2.5 | Unpinned version normalised to 1 | `DEFAULT_TYPE_VERSION` at extraction, so name and wire agree | same test |
| 2.5 | Local names unique; wire names unchanged | `local_name` claims names in source order, suffixing `_` | `003-reserved-names`; `test_colliding_local_names_stay_distinct_and_each_carries_its_own_value` |
| 2.5 | Warn when a parameter is renamed | `logger.warn`, on `FragmentClient.configuration.logger` | `test_escaping_warns_and_never_changes_the_wire_name` |
| 2.6 | Additive Schema changes do not break callers | Keyword arguments; identity-derived names | `sorbet/snapshots/typed_entries.rbi` snapshot, `test/snapshot_test.rb` |
| 3.1 | Batch shape and entry order | `to_entry_input`; `to_entry_inputs` maps in place | every fixture; `test_entry_order_is_preserved_and_raw_inputs_may_be_mixed_in` |
| 3.2 | Unset omitted, never `null` | A sentinel default marks an omitted keyword; `#set?` remembers, and `entry_input` skips what was never set | `005-unset-omitted`; `test_unset_is_omitted_and_explicit_nil_is_sent`; `test_an_unset_field_is_absent_from_the_request_body` |
| 3.3 | Wire names verbatim | `entry_parameters` keys on `wire_name` | `003-reserved-names`; `test_escaping_warns_and_never_changes_the_wire_name` |
| 3.4 | Baseline equivalence | Parsed-JSON equality against `expected.json` | all six fixtures |
| 3.4 | Strict equivalence (optional) | **Met.** See below | byte comparison in `conformance_test.rb`; `test_key_order_is_canonical` |
| 3.5 | Raw and typed in one batch | `to_entry_inputs` passes non-payloads through untouched | `test_typed_and_raw_entries_may_be_mixed_and_keep_their_order` |
| 3.6 | Everything accepted serialises | `add_ledger_entries` converts every payload in `entries` before the encoder; the sig rejects a non-array | `add_ledger_entries_test.rb` asserts on the request body, not on the hash |
| 4 | Atomicity, per-entry IK replay, narrowing, per-entry errors | The `AddLedgerEntries` operation selects `results`, and `errors { ik ... }` on `AddLedgerEntriesError` | `test_results_are_returned_per_entry_with_ik_replay`; `test_per_entry_errors_are_surfaced_with_the_ik_that_identifies_them` |

---

## Strict profile

This SDK meets the optional strict (byte-equivalence) profile, and the
conformance runner asserts it alongside the baseline.

- **Canonical key order.** `to_entry_input` inserts keys in lexicographic order at
  every level, `parameters` in source order. Ruby hashes are insertion-ordered and
  `JSON.generate` preserves that, so the order the payload is built in is the
  order on the wire. Asserted rather than assumed: nothing in the code fails if a
  key is inserted out of order, which is exactly why `test_key_order_is_canonical`
  exists.
- **Encoder settings.** `JSON.generate` escapes neither non-ASCII nor `<`, `>`,
  `&`, so `006-non-ascii` needs no special handling. Verified through the real
  transport in `test_non_ascii_and_html_significant_parameter_values_survive_the_transport`,
  since the encoder that matters is `graphql-client`'s, not ours.
- **No float-typed parameters.** Fragment binds `Int96` to strings, so nothing
  reaches the encoder as a float unless a Schema declares `Float` — in which case
  Ruby and Go would agree anyway and Python would not.

---

## Parameter order in the generated signature

§2.4's prohibition on reordering — "not alphabetically, and not required-first" —
is read here as a constraint on the wire, not on the generated signature. Fragment
accepts reordering in a signature as long as parameters are supplied **by name**,
which is what §2.6 actually depends on.

That matters because Sorbet refuses a `sig` that interleaves required and optional
keyword arguments:

```
Malformed `sig`. Required parameter `isExternal` must be declared before all the
optional ones
```

Ruby itself permits any order; Sorbet does not. So the RBI groups required
parameters first, preserving source order within each group. These are keyword
arguments, so declaration order is invisible to a caller and §2.6's guarantee is
unaffected. Source order is preserved on the wire, which is where §2.4 is
observable and where `004-param-order` and the strict-profile byte comparison
enforce it. `fragment-python` has the same constraint from ariadne, which also
emits required arguments first.

---

## Deviations

**Parameter names are kept verbatim (§2.5).** Python snake_cases them; this SDK
does not. Two reasons. The rest of this SDK already passes GraphQL variables
verbatim — `client.create_ledger(schemaKey: ...)` — so snake_casing only
`parameters` would be inconsistent. And verbatim names cannot collide the way
§2.5 warns about: `user_id` and `userId` stay two names instead of reducing to
one. A name is escaped with a trailing `_` only when a payload already responds to
it, which is read by reflection off `TypedLedgerEntry` rather than hand-listed, so
adding a method to the base class cannot silently start shadowing a parameter.

**Runtime type checking of parameters.** Not done. Presence and unknown names are
checked at runtime; types are the RBI's job. Mapping every custom scalar to a Ruby
class at runtime would mean rejecting values the API accepts as soon as the Schema
gains a scalar this SDK has not heard of. `test/type_check_test.rb` is what makes
the static half real: it runs `srb tc` over deliberately wrong calls and asserts
they are rejected.

**`typeVersion` is always sent.** §2.5 permits it, since an unpinned entry
resolves to version 1 server-side. It is the one value this SDK supplies that the
operation did not state.

---

## Gaps

Recorded rather than quietly absent.

- **`posted` accepts a `String`, not a `Time`.** The wire type is a `DateTime`
  scalar, and this SDK does no conversion — passing a `Time` would serialize as
  Ruby's default `to_s`, which the API rejects. Consistent with the rest of the
  SDK, which also passes timestamps through as written, but a caller has to format
  them. Statically enforced by the RBI.
- **Payload registration is global.** `TypedEntries.load` defines constants under
  `FragmentClient::Entries` and records them in a process-wide registry, guarded by
  a mutex so concurrent client construction cannot lose a class. Fine for the
  load-once case this is built for; two Schemas in one process that declare the same
  entry type at the same version would collide, and the first one loaded wins with a
  warning.
- **`tags`, `groups` and `conditions` are typed as `T::Array[T.untyped]`.** Their
  element types are `LedgerEntryTagInput` and friends, which this SDK has no
  generated classes for — everywhere else it passes input objects as plain hashes.
- **Spec §6 is answered for this SDK.** `test/live_test.rb` runs against the real
  API when `FRAGMENT_CREDENTIALS` is set: an entry with `lines` absent and `type`
  present is accepted and expanded into lines server-side, and a repeated `ik`
  reports `isIkReplay` per entry. The other three SDKs still record it as open.
- **The batch endpoint is gated, for now.** The API requires an
  `x-fragment-experimental` header until its per-entry error contract is settled.
  That requirement is being removed, so the SDK does not send the header and
  `test/live_test.rb` injects it for its own run instead; delete that patch once the
  gate is gone. Every offline test passed while the endpoint was unreachable, which
  is why the live tests exist at all.
- **The upstream fixture gaps remain upstream.** Five of the six that
  `shared-spec/CONTRIBUTING.md` records as cheap are covered here by
  `test/typed_entries_test.rb` instead. That is a weaker guarantee than a shared
  fixture — it means this SDK agrees with its own reading of the spec, not that
  four SDKs agree with each other — so they are still worth adding upstream.

---

## Working on this

```bash
nix-shell           # ruby 3.3 + bundler; see shell.nix
bundle install
bundle exec rake    # tests and srb tc
```

| Task | Command |
| --- | --- |
| Tests | `bundle exec rake test` |
| Typecheck | `bundle exec rake typecheck` |
| Regenerate the payload RBI snapshot | `bundle exec rake snapshot` |
| Regenerate gem RBIs and annotations | `bundle exec rake sorbet:update` |

The snapshot is the reviewable record of the surface callers touch. Regenerate it
deliberately and read the diff: anything renamed or removed, and any optional
parameter that became required, breaks existing call sites.

[spec]: https://github.com/fragment-dev/graphql-queries/blob/main/shared-spec/typed-batch-entries.md
