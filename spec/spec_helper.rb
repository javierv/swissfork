RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:expect, :should]
  end

  config.mock_with :rspec do |c|
    c.syntax = [:expect, :should]
  end
end

# TODO: put in in a module,
# the same way #stub is available.
class Object
  def stub_opponents(opponents)
    stub(opponents: opponents)
  end
end