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
    stub(opponents: opponents - [self])
  end

  def stub_preference(colour_preference)
    stub(colour_preference: colour_preference)
  end

  def stub_degree(degree)
    require "swissfork/preference_degree"
    stub(preference_degree: Swissfork::PreferenceDegree.new(degree))
  end
end