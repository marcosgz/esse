# frozen_string_literal: true

begin
  require 'rainbow'
rescue LoadError
end

module Esse
  module ColorOutput
    STYLES = {
      debug: {
        symbol: '•',
        attributes: [:cyan, :bold, :bright],
      },
      wait: {
        symbol: '…',
        attributes: [:cyan, :bold, :bright],
      },
      info: {
        symbol: 'ℹ',
        attributes: [:blue, :bold, :bright],
      },
      success: {
        symbol: '✔',
        attributes: [:green, :bold, :bright],
      },
      warn: {
        symbol: '⚠',
        attributes: [:yellow, :bold, :bright],
      },
      error: {
        symbol: '⨯',
        attributes: [:red, :bold, :bright],
      },
      fatal: {
        symbol: '!',
        attributes: [:red, :bold, :bright],
      },
    }.freeze

    module_function

    def colorize(text, *attributes)
      if defined? Rainbow
        attributes.reduce(Rainbow(text)) { |p, a| p.public_send(a) }
      else
        text
      end
    end

    def print_wait(message, **options)
      print_color(message, level: :wait, **options)
    end

    def print_info(message, **options)
      print_color(message, level: :info, **options)
    end

    def print_success(message, **options)
      print_color(message, level: :success, **options)
    end

    def print_warn(message, **options)
      print_color(message, level: :warn, output: :stderr, **options)
    end

    def print_fatal(message_or_error, backtrace: false, exit_status: 1, **options)
      print_error(message_or_error, level: :fatal, backtrace: backtrace, **options)

      if exit_status
        exit_status = exit_status.is_a?(Integer) ? exit_status : 1
        exit(exit_status)
      end
    end

    def print_error(message_or_error, backtrace: false, **options)
      options[:level] ||= :error
      message = message_or_error.to_s

      print_color(message, output: :stderr, **options)

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

    def print_color(message, level: :info, output: $stdout, newline: true, **fields)
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

      message = format_color(level, message, **fields)

      newline ? output.puts(message) : output.print(message)
    end

    def format_color(level, message, **fields)
      style = STYLES.fetch(level)
      symbol = colorize(style.fetch(:symbol), *style.fetch(:attributes))

      format("  %<symbol>s  #{message}", symbol: symbol, **fields)
    end
  end
end
