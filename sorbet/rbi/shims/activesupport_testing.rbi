# typed: strict

# `sorbet/rbi/annotations/activesupport.rbi` (from sorbet-typed) annotates
# `ActiveSupport::Testing::ErrorReporterAssertions#assert_error_reported`, whose
# return type is a class nested inside a module that is only loaded when Minitest
# is already present. `tapioca gem` does not load it, so the annotation is left
# referencing a constant nothing declares.
#
# activesupport reaches this gem transitively, through graphql-client; nothing
# here uses its test helpers. This declares just enough for the annotation to
# resolve.
module ActiveSupport
  module Testing
    module ErrorReporterAssertions
      module ErrorCollector
        class Report; end
      end
    end
  end
end
