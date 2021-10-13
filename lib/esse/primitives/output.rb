# frozen_string_literal: true

begin
  require 'rainbow'
rescue LoadError
end

module Esse
  module Output
    module_function

    def formatted_runtime(number)
      colorize(sprintf('%.3f ms', number), :lightgray)
    end

    def colorize(text, *attributes)
      if defined? Rainbow
        attributes.reduce(Rainbow(text)) { |p, a| p.public_send(a) }
      else
        text
      end
    end

    def print_error(message_or_error, backtrace: false, **options)
      options[:level] ||= :error
      message = message_or_error.to_s

      print_message(message, output: :stderr, **options)

      if message_or_error.is_a?(Exception) && backtrace
        limit = backtrace.is_a?(Integer) ? backtrace : -1
        print_backtrace(message_or_error, limit: limit, level: options[:level])
      end
    end

    def print_backtrace(error, limit: -1, **options)
      return unless error.respond_to?(:backtrace)
      return if error.backtrace.nil?

      error.backtrace[0..limit].each { |frame| print_error(frame, **options) }
    end

    def print_message(message, level: :info, output: $stdout, newline: true, **fields)
      output = \
        case output
        when :stdout, 'stdout'
          $stdout
        when :stderr, 'stderr'
          $stderr
        when IO
          output
        else
          raise ArgumentError, "Invalid output #{output.inspect}"
        end

      message = format(message, **fields)
      newline ? output.puts(message) : output.print(message)
    end
  end
end
