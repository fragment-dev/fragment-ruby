# typed: true
require 'minitest/autorun'
require 'fragment_client'

class GemTest < Minitest::Test
  def test_gem_can_be_required
    assert defined?(FragmentClient)
    assert defined?(FragmentGraphQl)
  end
end