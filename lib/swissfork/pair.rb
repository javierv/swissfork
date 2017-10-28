require "simple_initialize"
require "swissfork/game"

module Swissfork
  # Contains all data related to a game.
  #
  # Currently it only contains which players played the game,
  # but result information will be added in the future.
  class Pair
    initialize_with :s1_player, :s2_player

    attr_reader :result
    include Comparable

    def players
      @players ||= if no_players_have_colour_preference?
        players_ordered_by_initial_colours
      elsif players_ordered_by_preference.first.colour_preference == :black
        players_ordered_by_preference.reverse
      else
        players_ordered_by_preference
      end
    end

    def result=(result)
      players.each do |player|
        points_before_playing[player.id] = player.points
        player.add_game(Game.new(player, self))
      end
      @result = result
    end

    def hash
      numbers.hash
    end

    def last
      s2_player
    end

    def points_before_playing
      @points_before_playing ||= {}
    end

    # Helper method to make tests easier to write
    def numbers
      # Hack to let tests having no colours use this method.
      if no_players_have_colour_preference?
        [s1_player, s2_player].map(&:number)
      else
        players.map(&:number)
      end
    end

    def same_absolute_high_difference?
      same_absolute_preference? && both_have_high_difference?
    end

    def same_colour_three_times?
      same_absolute_preference? && !both_have_high_difference?
    end

    def same_colour_preference?
      colour_preferences.any? && colour_preferences.uniq.count == 1
    end

    def same_strong_preference?
      same_colour_preference? && (
        s1_player.preference_degree == :strong && [:strong, :absolute].include?(s2_player.preference_degree) ||
        [:strong, :absolute].include?(s1_player.preference_degree) && s2_player.preference_degree == :strong
      )
    end

    def heterogeneous?
      s1_player.points != s2_player.points
    end

    def eql?(pair)
      ([pair.s1_player, pair.s2_player] - [s1_player, s2_player]).empty?
    end

    def ==(pair)
      eql?(pair)
    end

    def <=>(pair)
      [pair.points.max, pair.points.sum, [s1_player, s2_player].min] <=> [points.max, points.sum, [pair.s1_player, pair.s2_player].min]
    end

    def points
      [s1_player, s2_player].map(&:points)
    end

  private
    def same_absolute_preference?
      same_colour_preference? && s1_player.preference_degree == :absolute &&
        s2_player.preference_degree == :absolute
    end

    def both_have_high_difference?
      # TODO: use .abs; add test.
      s1_player.colour_difference > 1 && s2_player.colour_difference > 1
    end

    def colour_preferences
      @colour_preferences ||= [s1_player, s2_player].map(&:colour_preference)
    end

    def players_ordered_by_preference
      @players_ordered_by_preference ||=
        [s1_player, s2_player].sort_by(&:preference_priority)
    end

    def no_players_have_colour_preference?
      !s1_player.colour_preference && !s2_player.colour_preference
    end

    def players_ordered_by_initial_colours
      higher_player, lower_player = [s1_player, s2_player].sort

      if higher_player.number.odd?
        [higher_player, lower_player] # TODO: it depends on the initial colour
      else
        [lower_player, higher_player]
      end
    end
  end
end
