# frozen_string_literal: true
# typed: true

require 'minitest/autorun'
require 'fragment_client'

class GemTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)

  def test_gem_can_be_required
    assert defined?(FragmentClient)
    assert defined?(FragmentGraphQl)
  end

  def test_the_gemspec_ships_every_library_file
    # `s.files` is a hand-maintained list, so a new file under `lib/` is shipped
    # only if someone remembered. A missing one does not fail anything until a
    # released gem raises LoadError on require.
    spec = Gem::Specification.load(File.join(ROOT, 'fragment-dev.gemspec'))
    on_disk = Dir.glob('lib/**/*.rb', base: ROOT).sort

    assert_equal on_disk, (spec.files & on_disk).sort,
                 "not listed in fragment-dev.gemspec: #{(on_disk - spec.files).inspect}"
  end
end
