# frozen_string_literal: true

module EsseConfig
  def reset_esse_config
    Esse.instance_variable_set(:@config, nil)
  end
end

RSpec.configure do |config|
  config.include EsseConfig
end
