# Compatibility shim for Ruby 4.x / older Jekyll 3.x
# Ruby 4 removed String#tainted? from the default runtime.
# Liquid 4 still calls this method during rendering.
module Ruby4Compat
  def tainted?
    false
  end
end

class Object
  include Ruby4Compat
end
