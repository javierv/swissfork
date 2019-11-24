require "simple_initialize"
require "swissfork/game"
require "swissfork/player_compatibility"
require "forwardable"

module Swissfork
  # Contains all data related to a game.
  class Pair
    include Comparable

    extend Forwardable
    def_delegators :player_compatibility,
      :same_absolute_high_difference?,
      :same_colour_three_times?,
      :same_preference?,
      :white_preferences?,
      :black_preferences?,
      :same_strong_preference?,
      :no_preference_against_colour?

    attr_reader :result

    initialize_with :s1_player, :s2_player

    def players
      @players ||=
        if player_compatibility.no_preferences?
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
      players.map(&:number)
    end

    def heterogeneous?
      s1_player.points != s2_player.points
    end

    def eql?(pair)
      (pair.unordered_players - unordered_players).empty?
    end

    def ==(pair)
      eql?(pair)
    end

    def <=>(pair)
      [pair.points.max, pair.points.sum, unordered_players.min] <=> [points.max, points.sum, pair.unordered_players.min]
    end

  protected

    def points
      unordered_players.map(&:points)
    end

    def unordered_players
      [s1_player, s2_player]
    end

  private

    def players_ordered_by_preference
      @players_ordered_by_preference ||=
        unordered_players.sort_by(&:preference_priority)
    end

    def players_ordered_by_initial_colours
      higher_player, lower_player = unordered_players.sort

      if higher_player.prefers_white_by_default?
        [higher_player, lower_player]
      else
        [lower_player, higher_player]
      end
    end

    def player_compatibility
      PlayerCompatibility.new(*unordered_players)
    end
  end
end
