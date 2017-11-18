require "simple_initialize"
require "swissfork/preference_priority"
require "set"

module Swissfork
  # Contains information about the games a player has
  # played, its opponents, and results. That information is
  # used to calculate the player's colour preference and
  # compatible opponents.
  #
  # The player's personal information is handled by the
  # Inscription class.
  class Player
    include Comparable
    initialize_with :id
    attr_accessor :inscription

    def number
      @number ||= id
    end
    attr_writer :number

    def games
      @games ||= []
    end

    def add_game(game)
      empty_colours_cache
      empty_opponents_cache
      games << game
    end

    def opponents
      @opponents ||= Set.new(games.select(&:played?).map(&:opponent))
    end

    def floats
      games.map(&:float)
    end

    def colours
      @colours ||= games.map(&:colour)
    end

    def points
      games.map(&:points_received).reduce(0.0, :+)
    end

    def had_bye?
      games.any?(&:bye?)
    end

    def descended_in_the_previous_round?
      [:down, :bye].include?(floats.last)
    end

    def ascended_in_the_previous_round?
      floats.last == :up
    end

    def descended_two_rounds_ago?
      [:down, :bye].include?(floats[-2])
    end

    def ascended_two_rounds_ago?
      floats[-2] == :up
    end

    def colour_preference
      @colour_preference ||= if colours.any?
        if last_two_colours_were_the_same?
          opposite_of_last_colour
        elsif colour_difference > 0
          :black
        elsif colour_difference < 0
          :white
        else
          opposite_of_last_colour
        end
      end
    end

    def preference_priority
      PreferencePriority.new(self)
    end

    def preference_degree
      @preference_degree ||= if colours.any?
        if last_two_colours_were_the_same?
          :absolute
        else
          case colour_difference.abs
          when 0 then :mild
          when 1 then :strong
          else :absolute
          end
        end
      end
    end

    def colour_difference
      colours.select { |colour| colour == :white }.count -
      colours.select { |colour| colour == :black }.count
    end

    def inspect
      number.to_s
    end

    def <=>(other_player)
      [other_player.points, number] <=> [points, other_player.number]
    end

    def compatible_opponents_in(players)
      players.select { |player| compatibilities[:opponent][player] }
    end

    def compatible_colours_in(players)
      players.select { |player| compatibilities[:colour][player] }
    end

    def topscorer?
      @topscorer
    end
    attr_writer :topscorer

    def rating
      inscription.rating
    end

    def name
      inscription.name
    end

    def prefers_white_by_default?
      number.odd? # TODO: it depends on the initial colour
    end

  private
    def last_two_colours_were_the_same?
      colours.compact[-1] == colours.compact[-2]
    end

    def opposite_of_last_colour
      if colours.compact.last == :white
        :black
      else
        :white
      end
    end

    def compatibilities
      @compatibilities ||= {}.tap do |compatibilities|
        [:opponent, :colour].each do |criterion|
          compatibilities[criterion] = Hash.new do |compatibility, player|
            compatibility[player] = send("#{criterion}_compatible?", player)
          end
        end
      end
    end

    def opponent_compatible?(player)
      !opponents.include?(player) && player.id != id && (
        preference_degree != :absolute || player.preference_degree != :absolute ||
        player.colour_preference != colour_preference ||
        topscorer? || player.topscorer?
      )
    end

    def colour_compatible?(player)
      !opponents.include?(player) && player.id != id &&
        (!colour_preference || player.colour_preference != colour_preference)
    end

    def empty_colours_cache
      @colours = nil
      @colour_preference = nil
      @preference_degree = nil
    end

    def empty_opponents_cache
      @compatibilities = nil
      @opponents = nil
    end
  end
end
