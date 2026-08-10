# Shared conformance fixtures

Vendored, do not edit here.

`conformance/` and `VERSION` are copied verbatim from `shared-spec/` in
[`fragment-dev/graphql-queries`][queries]. The fixtures are language-neutral and
shared by all four SDKs — if each SDK authored its own cases, all four could pass
and still disagree with each other. Changes belong upstream, and the
`updateSDKQueries` workflow syncs them back down.

The runner over them is `test/conformance_test.rb`, and it is Ruby-specific by
design. It resolves each `case.json` entry by `(type, typeVersion)` rather than by
class name, which is what keeps the fixtures neutral.

[queries]: https://github.com/fragment-dev/graphql-queries/tree/main/shared-spec
