# frozen_string_literal: true

# Helper methods to create Index classes
module ClassHelpers
  def stub_index(name, superclass = nil, &block)
    superclass ||= Esse::Index
    klass_name = "#{Esse::Hstring.new(name).camelize}Index"
    klass = stub_class(klass_name, superclass)
    klass.class_eval(&block) if block
    klass.define_singleton_method(:index_directory) do
      Esse.config.indices_directory.join(Esse::Hstring.new(klass_name).underscore.to_s).to_s
    end
    klass
  end

  def stub_class(name, superclass = nil, &block)
    klass = Class.new(superclass || Object, &block)
    stub_const(Esse::Hstring.new(name).camelize.to_s, klass)
  end
end
