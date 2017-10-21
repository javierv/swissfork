module Swissfork
  # Compares degrees of preferences.
  # Only accepted values are described in A.6.
  class PreferenceDegree
    include Comparable
    attr_reader :degree

    def initialize(degree)
      raise "Unknown degree: #{degree}" unless degrees.include?(degree)
      @degree = degree
    end

    def <=>(preference)
      degrees.index(preference.degree) <=> degrees.index(degree)
    end

    def strong?
      degree == :strong
    end

  private
    def degrees
      [:absolute, :strong, :mild, :none]
    end
  end
end
