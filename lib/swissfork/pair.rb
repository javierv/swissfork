require "simple_initialize"

module Swissfork
  # Contains all data related to a game.
  #
  # Currently it only contains which players played the game,
  # but color and result information will be added in the future.
  class Pair
    initialize_with :s1_player, :s2_player
    include Comparable

    def players
      [s1_player, s2_player]
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
      players.min <=> pair.players.min
    end
  end
end
