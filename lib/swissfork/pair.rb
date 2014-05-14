module Swissfork
  class Pair
    attr_reader :s1_player, :s2_player

    def initialize(s1_player, s2_player)
      @s1_player = s1_player
      @s2_player = s2_player
    end

    def numbers
      [s1_player.number, s2_player.number]
    end

    def include?(player)
      player == s1_player || player == s2_player
    end

    def compatible?
      s1_player.compatible_with?(s2_player)
    end

    def eql?(pair)
      pair.respond_to?(:s1_player) && pair.s1_player == s1_player && pair.s2_player == s2_player
    end

    def ==(pair)
      eql?(pair)
    end
  end
end
