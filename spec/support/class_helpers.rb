# frozen_string_literal: true

# Helper methods to create Index classes
module ClassHelpers
  def stub_index(name, superclass = nil, &block)
    superclass ||= Esse::Index
    stub_class("#{Esse::Hstring.new(name).camelize}Index", superclass)
      .tap { |i| i.class_eval(&block) if block }
  end

  def stub_class(name, superclass = nil, &block)
    klass = Class.new(superclass || Object, &block)
    stub_const(Esse::Hstring.new(name).camelize.to_s, klass)
  end
end
