require "simple_initialize"

module Swissfork
  class PlayersDifference
    include Comparable

    initialize_with :s1_player, :s2_player

    def <=>(other_difference)
      if difference == other_difference.difference
        other_difference.s1_player <=> s1_player
      else
        difference <=> other_difference.difference
      end
    end

    def difference
      (s2_player.number - s1_player.number).abs
    end
  end
end
