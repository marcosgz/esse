module Fixtures
  def fixture_path(relative_path)
    path = File.expand_path(File.join('../fixtures/', relative_path), __dir__)
    raise "No fixture found for ./spec/fixtures/#{relative_path}" unless File.exist?(path)

    path
  end

  def fixture(relative_path, **assigns)
    path = fixture_path(relative_path)

    content = File.read(path)
    case File.extname(path)
    when '.erb'
      value = ERB.new(content).result_with_hash(assigns: assigns)
      /\.yml\.erb$/.match?(path) ? YAML.safe_load(value) : value
    when '.yml'
      YAML.safe_load(content)
    else
      content
    end
  end
end
