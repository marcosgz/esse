# frozen_string_literal: true

require 'forwardable'

module Esse
  # The idea here is to add useful methods to the ruby core objects without
  # monkey patching.
  # And on this state and not thinking about to add ActiveSupport dependency
  class Hstring
    extend Forwardable

    def_delegators :@value, :==, :eq, :to_s, :to_sym, :inspect, :sub, :capitalize
    attr_reader :value

    def self.def_conventional(bang_method, conv_method = nil)
      conv_method ||= bang_method.to_s.sub(/[!?]*$/, '')
      if public_instance_methods.include?(conv_method)
        msg = format(
          'Equivalent %<conv>p already defined for the bang method %<bang>p',
          conv: conv_method.to_s,
          bang: bang_method.to_s,
        )
        raise(SyntaxError, msg)
      end

      unless public_instance_methods.include?(bang_method)
        msg = format(
          'Undefined method %<bang>p for %<klass>p',
          bang: bang_method.to_s,
          klass: self,
        )
        raise(SyntaxError, msg)
      end

      define_method(conv_method) do |*args|
        self.class.new(self).public_send(bang_method, *args)
      end
    end

    def initialize(value)
      @value = value.to_s
    end

    def camelize!
      @value = @value.split(/(?=[_A-Z])/).map { |str| str.tr('_', '').capitalize }.join
      self
    end
    def_conventional :camelize!, :camelize

    def demodulize!
      @value = @value.split('::').last
      self
    end
    def_conventional :demodulize!

    def modulize!
      @value = @value.split(%r{::|\\|/}).map { |part| self.class.new(part).camelize.to_s }.join('::')
      self
    end
    def_conventional :modulize!

    def underscore!
      @value = @value
        .sub(/^::/, '')
        .gsub('::', '/')
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('-', '_')
        .tr('.', '_')
        .gsub(/\s/, '_')
        .gsub(/__+/, '_')
        .downcase

      self
    end
    def_conventional :underscore!

    def presence!
      return @value = nil if @value == ''
      return @value = nil unless @value

      @value
    end
    def_conventional :presence!
  end
end
