# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `ffi-compiler` gem.
# Please instead update this file by running `bin/tapioca gem ffi-compiler`.

# source://ffi-compiler//lib/ffi-compiler/loader.rb#5
module FFI
  private

  def custom_typedefs; end

  class << self
    # source://ffi/1.16.3/lib/ffi/types.rb#57
    def add_typedef(old, add); end

    # source://ffi/1.16.3/lib/ffi/errno.rb#34
    def errno; end

    # source://ffi/1.16.3/lib/ffi/errno.rb#40
    def errno=(error); end

    # @raise [TypeError]
    #
    # source://ffi/1.16.3/lib/ffi/types.rb#76
    def find_type(name, type_map = T.unsafe(nil)); end

    # source://ffi/1.16.3/lib/ffi/compat.rb#35
    def make_shareable(obj); end

    # source://ffi/1.16.3/lib/ffi/library.rb#46
    def map_library_name(lib); end

    # source://ffi/1.16.3/lib/ffi/types.rb#200
    def type_size(type); end

    # source://ffi/1.16.3/lib/ffi/types.rb#51
    def typedef(old, add); end

    private

    # source://ffi/1.16.3/lib/ffi/types.rb#62
    def __typedef(old, add); end

    def custom_typedefs; end
  end
end

class FFI::ArrayType < ::FFI::Type
  def initialize(_arg0, _arg1); end

  def elem_type; end
  def length; end
end

class FFI::Buffer < ::FFI::AbstractMemory
  def initialize(*_arg0); end

  def +(_arg0); end
  def inspect; end
  def length; end
  def order(*_arg0); end
  def slice(_arg0, _arg1); end

  private

  def initialize_copy(_arg0); end

  class << self
    def alloc_in(*_arg0); end
    def alloc_inout(*_arg0); end
    def alloc_out(*_arg0); end
    def new_in(*_arg0); end
    def new_inout(*_arg0); end
    def new_out(*_arg0); end
  end
end

# source://ffi-compiler//lib/ffi-compiler/platform.rb#1
module FFI::Compiler; end

# source://ffi-compiler//lib/ffi-compiler/loader.rb#7
module FFI::Compiler::Loader
  class << self
    # source://ffi-compiler//lib/ffi-compiler/loader.rb#28
    def caller_path(line = T.unsafe(nil)); end

    # @raise [LoadError]
    #
    # source://ffi-compiler//lib/ffi-compiler/loader.rb#8
    def find(name, start_path = T.unsafe(nil)); end
  end
end

# source://ffi-compiler//lib/ffi-compiler/platform.rb#2
class FFI::Compiler::Platform
  # source://ffi-compiler//lib/ffi-compiler/platform.rb#13
  def arch; end

  # @return [Boolean]
  #
  # source://ffi-compiler//lib/ffi-compiler/platform.rb#25
  def mac?; end

  # source://ffi-compiler//lib/ffi-compiler/platform.rb#9
  def map_library_name(name); end

  # source://ffi-compiler//lib/ffi-compiler/platform.rb#21
  def name; end

  # source://ffi-compiler//lib/ffi-compiler/platform.rb#17
  def os; end

  class << self
    # source://ffi-compiler//lib/ffi-compiler/platform.rb#5
    def system; end
  end
end

# source://ffi-compiler//lib/ffi-compiler/platform.rb#3
FFI::Compiler::Platform::LIBSUFFIX = T.let(T.unsafe(nil), String)

class FFI::FunctionType < ::FFI::Type
  def initialize(*_arg0); end

  def param_types; end
  def return_type; end
end

module FFI::LastError
  private

  def error; end
  def error=(_arg0); end

  class << self
    def error; end
    def error=(_arg0); end
  end
end

class FFI::MemoryPointer < ::FFI::Pointer
  def initialize(*_arg0); end

  class << self
    def from_string(_arg0); end
  end
end

module FFI::NativeType; end
class FFI::NullPointerError < ::RuntimeError; end

class FFI::StructByValue < ::FFI::Type
  # @return [StructByValue] a new instance of StructByValue
  def initialize(_arg0); end

  def layout; end
  def struct_class; end
end

class FFI::Type
  # @return [Type] a new instance of Type
  def initialize(_arg0); end

  def alignment; end
  def inspect; end
  def size; end
end

class FFI::Type::Builtin < ::FFI::Type
  def inspect; end
end

class FFI::Type::Mapped < ::FFI::Type
  def initialize(_arg0); end

  def converter; end
  def from_native(*_arg0); end
  def native_type; end
  def to_native(*_arg0); end
  def type; end
end