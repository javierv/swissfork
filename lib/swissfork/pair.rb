require "simple_initialize"
require "swissfork/game"

module Swissfork
  # Contains all data related to a game.
  #
  # Currently it only contains which players played the game,
  # but result information will be added in the future.
  class Pair
    initialize_with :s1_player, :s2_player

    def self.for(s1_player, s2_player)
      @pairs ||= {}
      @pairs[[s1_player, s2_player].map(&:number).sort] ||= new(s1_player, s2_player)
    end

    def self.clear
      @pairs = {}
    end

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
      players.each { |player| player.add_game(Game.new(player, self)) }
      @result = result
    end

    def hash
      numbers.hash
    end

    def last
      s2_player
    end

    # Helper method to make tests easier to write
    def numbers
      # Hack to let tests having no colours use this method.
      @numbers ||= if no_players_have_colour_preference?
        [s1_player, s2_player].map(&:number).sort
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
      # TODO: Using array "-" for performance reasons. Check if it still
      # holds true when the program is more mature.
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
        if s1_player.colour_preference == s2_player.colour_preference
          players_with_same_colour_ordered_by_preference
        else
          players_with_different_colour_ordered_by_preference
        end
    end

    def players_with_same_colour_ordered_by_preference
      if s1_player.stronger_preference_than?(s2_player)
        [s1_player, s2_player]
      elsif s2_player.stronger_preference_than?(s1_player)
        [s2_player, s1_player]
      else
        players_ordered_inverting_last_different_colours
      end
    end

    def players_with_different_colour_ordered_by_preference
      if s1_player.colour_preference.nil?
        [s2_player, s1_player]
      else
        [s1_player, s2_player]
      end
    end

    def players_ordered_inverting_last_different_colours
      if s1_player.colours == s2_player.colours
        players_ordered_by_rank
      elsif last_different_colours
        if last_different_colours[0] == s1_player.colour_preference
          [s2_player, s1_player]
        else
          [s1_player, s2_player]
        end
      else
        [higher_player, lower_player]
      end
    end

    def players_ordered_by_rank
      [higher_player, lower_player]
    end

    def higher_player
      [s1_player, s2_player].sort.first
    end

    def lower_player
      [s1_player, s2_player].sort.last
    end

    def last_different_colours
      s1_player.colours.compact.zip(s2_player.colours.compact).select do |colours|
        colours.compact.uniq.count > 1
      end.last
    end

    def no_players_have_colour_preference?
      !s1_player.colour_preference && !s2_player.colour_preference
    end

    def players_ordered_by_initial_colours
      if higher_player.number.odd?
        [higher_player, lower_player] # TODO: it depends on the initial colour
      else
        [lower_player, higher_player]
      end
    end
  end
end
