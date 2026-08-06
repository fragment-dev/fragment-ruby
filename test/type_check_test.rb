# frozen_string_literal: true
# typed: true

require 'minitest/autorun'
require 'open3'
require 'tmpdir'

# That wrong calls to a typed payload are actually *rejected*.
#
# `sorbet/type_checks/typed_entries.rb` covers the positive direction and is
# checked by the repository's own `srb tc`. This covers the negative one, which
# Sorbet cannot express inline: there is no way to mark a line as
# expected-to-fail, so the only way to assert an error is to run `srb tc` over a
# file and read what comes back.
#
# Without this, the RBI could loosen every parameter to `T.untyped` and both the
# snapshot and the positive checks would still pass -- while callers silently lost
# the type errors the whole feature exists to give them.
class TypeCheckTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)

  # Each case is a snippet plus the substring `srb tc` must report for it.
  CASES = {
    'a wrong parameter type' => [
      "FragmentClient::Entries::AuthCaptureV1.new(ik: 'i', ledger_ik: 'l', " \
      "user_id: 123, capture_amount: '1')",
      'Expected `String` but found `Integer(123)` for argument `user_id`'
    ],
    'a missing required parameter' => [
      "FragmentClient::Entries::AuthCaptureV1.new(ik: 'i', ledger_ik: 'l', user_id: 'u')",
      'Missing required keyword argument `capture_amount`'
    ],
    'a parameter the entry type does not declare' => [
      "FragmentClient::Entries::AuthCaptureV1.new(ik: 'i', ledger_ik: 'l', user_id: 'u', " \
      "capture_amount: '1', nope: 'x')",
      'Unrecognized keyword argument `nope`'
    ],
    # `lines` cannot be combined with an entry that has a `type` (spec 2.3a).
    'lines' => [
      "FragmentClient::Entries::AuthCaptureV1.new(ik: 'i', ledger_ik: 'l', user_id: 'u', " \
      "capture_amount: '1', lines: [])",
      'Unrecognized keyword argument `lines`'
    ],
    # The wire name, not the name the payload exposes it under (spec 2.5).
    'a parameter under its unescaped Schema name' => [
      "FragmentClient::Entries::ReservedV1.new(ik: 'i', ledger_ik: 'l', type: 't', " \
      "class: 'c', posted_: 'p', userId: 'u')",
      'Unrecognized keyword argument `class`'
    ],
    # An optional parameter's reader is nilable, so it still has to be narrowed --
    # just as a plain nilable value, with no sentinel to learn about.
    'an optional parameter read without narrowing' => [
      "FragmentClient::Entries::UserFundsAccountV2.new(ik: 'i', ledger_ik: 'l', amount: '1', " \
      'isExternal: true, tagKeys: [], mode: :m).feeAmount.length',
      'Method `length` does not exist on `NilClass` component of `T.nilable(String)`'
    ],
    'a batch method given something other than an array' => [
      "FragmentClient.new('id', 'secret').add_ledger_entries(entries: 'not an array')",
      'for argument `entries`'
    ]
  }.freeze

  def test_each_wrong_call_is_rejected
    CASES.each do |description, (snippet, expected)|
      errors = typecheck(snippet)

      assert_includes errors, expected,
                      "#{description} was not rejected as expected.\nsrb tc said:\n#{errors}"
    end
  end

  def test_the_positive_checks_are_not_vacuous
    # `sorbet/type_checks/typed_entries.rb` only means something if the same
    # harness reports nothing for a correct call.
    assert_empty typecheck(
      "FragmentClient::Entries::AuthCaptureV1.new(ik: 'i', ledger_ik: 'l', " \
      "user_id: 'u', capture_amount: '1')"
    )
  end

  private

  # Run `srb tc` over the repository plus one extra file holding `snippet`.
  #
  # The file lives outside the repository, so a failed run cannot leave a stray
  # source file behind; Sorbet still loads the whole project from `sorbet/config`,
  # which is what makes the payload RBI visible.
  def typecheck(snippet)
    Dir.mktmpdir('fragment-type-check') do |dir|
      path = File.join(dir, 'negative.rb')
      File.write(path, "# typed: true\n# frozen_string_literal: true\n\n#{snippet}\n")

      out, status = Open3.capture2e('bundle', 'exec', 'srb', 'tc', path, chdir: ROOT)
      return '' if status.success?

      # Only the extra file's errors; the repository itself is expected to be
      # clean, and `test_the_positive_checks_are_not_vacuous` is what proves it.
      out.lines.grep(/negative\.rb:/).join
    end
  end
end
