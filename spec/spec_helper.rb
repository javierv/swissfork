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

class Array
  def each_stub(methods)
    each { |player| player.stub(methods) }
  end

  def each_stub_opponents(opponents)
    each { |player| player.stub_opponents(opponents) }
  end

  def each_stub_preference(colour_preference)
    each { |player| player.stub_preference(colour_preference) }
  end

  def each_stub_degree(degree)
    each { |player| player.stub_degree(degree) }
  end
end
