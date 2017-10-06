RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:expect, :should]
  end

  config.mock_with :rspec do |c|
    c.syntax = [:expect, :should]
  end
end

require "set"

class Object
  def stub_opponents(opponents)
    stub(opponents: Set.new(opponents))
  end
end