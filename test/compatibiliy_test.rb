# frozen_string_literal: true
# typed: true

require 'test_helper'
require 'graphql/client'
require 'minitest/autorun'
require 'webmock/minitest'

class CompatibilityTest < Minitest::Test
  def test_warning_about_duplicate_all_rules_constant
    # Capture stderr to check warning messages
    original_stderr = $stderr
    $stderr = StringIO.new

    # Load fragment_client which should trigger the warning
    require 'fragment_client'

    warning_output = $stderr.string
    $stderr = original_stderr

    # Verify both warning messages appear
    assert_empty warning_output, "Expected no warnings but got: #{warning_output}"
  end
end
