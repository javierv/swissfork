require "simple_initialize"

module Swissfork
  class Pair
    initialize_with :s1_player, :s2_player

    def numbers
      [s1_player.number, s2_player.number]
    end

    def include?(player)
      player == s1_player || player == s2_player
    end

    def eql?(pair)
      pair.respond_to?(:s1_player) && pair.s1_player == s1_player && pair.s2_player == s2_player
    end

    def ==(pair)
      eql?(pair)
    end
  end
end
