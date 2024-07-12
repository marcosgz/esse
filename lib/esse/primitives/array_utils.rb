module Esse
  # The idea here is to add useful methods to the ruby standard objects without
  # monkey patching them
  module ArrayUtils
    module_function

    def wrap(object)
      if object.nil?
        []
      elsif object.respond_to?(:to_ary)
        object.to_ary || [object]
      else
        [object]
      end
    end
  end
end
