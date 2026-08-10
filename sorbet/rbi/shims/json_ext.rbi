# typed: strict

# `JSON::Ext::ParserConfig` is defined in the json gem's C extension, so
# `tapioca gem` does not see it -- but the generated RBI still contains the
# `JSON::Ext::Parser::Config = JSON::Ext::ParserConfig` alias that references it,
# which leaves `srb tc` with an unresolvable constant.
#
# Remove this once tapioca emits the class itself.
module JSON
  module Ext
    class ParserConfig; end
  end
end
