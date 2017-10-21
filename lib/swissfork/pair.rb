require "simple_initialize"

module Swissfork
  # Contains all data related to a game.
  #
  # Currently it only contains which players played the game,
  # but result information will be added in the future.
  class Pair
    initialize_with :s1_player, :s2_player
    include Comparable

    def players
      # TODO: add case when the lower player has got a stronger preference.
      if higher_player.colour_preference == :black
        [lower_player, higher_player]
      else
        [higher_player, lower_player]
      end
    end

    def higher_player
      [s1_player, s2_player].sort.first
    end

    def lower_player
      [s1_player, s2_player].sort.last
    end

    def hash
      numbers.hash
    end

    def last
      s2_player
    end

    def numbers
      players.map(&:number)
    end

    def same_colour_preference?
      s1_player.colour_preference && s2_player.colour_preference &&
        s1_player.colour_preference == s2_player.colour_preference
    end

    def heterogeneous?
      s1_player.points != s2_player.points
    end

    def eql?(pair)
      # TODO: Using array "-" for performance reasons. Check if it still
      # holds true when the program is more mature.
      ([pair.s1_player, pair.s2_player] - [s1_player, s2_player]).empty?
    end

    def ==(pair)
      eql?(pair)
    end

    def <=>(pair)
      [s1_player, s2_player].min <=> [pair.s1_player, pair.s2_player].min
    end
  end
end
