require "swissfork/bracket"

module Swissfork
  class LastBracket < Bracket
    def number_of_required_pairs
      if homogeneous?
        maximum_number_of_pairs
      else
        super
      end
    end
  end
end
