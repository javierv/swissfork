require "syntax_spec_helper"

# TODO: put in in a module,
# the same way #stub is available.
require "set"
class Object
  def stub_opponents(opponents)
    stub(opponents: opponents.to_set - [self])
  end

  def stub_preference(colour_preference)
    stub(colour_preference: colour_preference)
  end

  def stub_degree(degree)
    stub(preference_degree: degree)
  end
end