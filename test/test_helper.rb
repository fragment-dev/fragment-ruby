# frozen_string_literal: true
# typed: false

# Required first by every test file, so coverage measurement starts before
# anything under `lib/` loads -- SimpleCov cannot see an already-required file.
#
# Opt in with `bundle exec rake coverage`.
if ENV['COVERAGE']
  require 'simplecov'

  SimpleCov.start do
    enable_coverage :branch
    command_name 'minitest'
    cover 'lib/**/*.rb'
    skip %r{^/test/}
    skip %r{^/vendor/}
  end
end

require 'fragment_client'
