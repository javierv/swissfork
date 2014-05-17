module Swissfork
  class PlayersDifference
    include Comparable

    attr_reader :s1_player, :s2_player

    def initialize(s1_player, s2_player)
      @s1_player = s1_player
      @s2_player = s2_player
    end

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
