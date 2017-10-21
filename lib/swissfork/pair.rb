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
      if players_ordered_by_preference.first.colour_preference == :black
        players_ordered_by_preference.reverse
      else
        players_ordered_by_preference
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

    def same_absolute_high_difference?
      same_absolute_preference? && both_have_high_difference?
    end

    def same_colour_three_times?
      same_absolute_preference? && !both_have_high_difference?
    end

    def same_colour_preference?
      s1_player.colour_preference && s2_player.colour_preference &&
        s1_player.colour_preference == s2_player.colour_preference
    end

    def same_strong_preference?
      same_colour_preference? && s1_player.preference_degree.strong? &&
        s2_player.preference_degree.strong?
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

  private
    def same_absolute_preference?
      same_colour_preference? && s1_player.preference_degree.absolute? &&
        s2_player.preference_degree.absolute?
    end

    def both_have_high_difference?
      s1_player.colour_difference > 1 && s2_player.colour_difference > 1
    end

    def players_ordered_by_preference
      if higher_player.colour_preference == lower_player.colour_preference
        if lower_player.stronger_preference_than?(higher_player)
          [lower_player, higher_player]
        elsif higher_player.colours == lower_player.colours
          [higher_player, lower_player]
        else
          if last_different_colours[0] == higher_player.colour_preference
            [lower_player, higher_player]
          else
            [higher_player, lower_player]
          end
        end
      elsif higher_player.colour_preference == :none
        [lower_player, higher_player]
      else
        [higher_player, lower_player]
      end
    end

    def last_different_colours
      higher_player.colours.zip(lower_player.colours).select do |colours|
        colours.uniq.count > 1
      end.last
    end
  end
end
