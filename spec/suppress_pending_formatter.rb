class SuppressPendingFormatter < RSpec::Core::Formatters::ProgressFormatter
  RSpec::Core::Formatters.register self, :example_pending

  def example_pending(notification)
  end

  def dump_pending(notification)
  end
end
