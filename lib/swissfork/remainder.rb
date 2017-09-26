module Swissfork
  # This class isn't supposed to be used by other classes, with the
  # exception of the HeterogeneousBracket class.
  class Remainder < Bracket
  private
    def pairings_completed?
      established_pairs.count == s1.count
    end
  end
end
