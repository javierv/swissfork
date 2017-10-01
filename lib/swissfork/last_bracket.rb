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

    def still_unpaired_players
      if heterogeneous? && @bracket_already_paired
        players - (established_pairs + remainder_pairs).map(&:players).flatten
      else
        super
      end
    end
  end
end
