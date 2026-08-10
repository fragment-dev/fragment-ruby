# typed: strict
# frozen_string_literal: true

# Extra requires for `bundle exec tapioca gem`, which only loads what a gem's
# entry point loads. Without these, tapioca cannot see the constants and they end
# up in `sorbet/rbi/todo.rbi` as bare modules instead -- which is worse than
# absent, because `GraphQL::Client::HTTP` declared as a module makes
# `Class.new(GraphQL::Client::HTTP)` an error.
require 'graphql/client'
require 'graphql/client/http'
