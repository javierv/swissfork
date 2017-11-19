require "simple_initialize"
require "swissfork/preference_priority"
require "swissfork/player_compatibility"
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
      %i[down bye].include?(floats.last)
    end

    def ascended_in_the_previous_round?
      floats.last == :up
    end

    def descended_two_rounds_ago?
      %i[down bye].include?(floats[-2])
    end

    def ascended_two_rounds_ago?
      floats[-2] == :up
    end

    def colour_preference
      @colour_preference ||=
        if colours.any?
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
      @preference_degree ||=
        if colours.any?
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

    def self.compatibility_criteria
      %i[opponent colour strong_colour]
    end

    # These methods use a ruby Hash cache to reduce the amount of
    # time dedicated to calculate compatibilities between players
    compatibility_criteria.each do |criterion|
      define_method "compatible_#{criterion}s_in" do |players|
        players.select { |player| compatibilities[criterion][player] }
      end
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

    def compatibility_criteria
      self.class.compatibility_criteria
    end

    def compatibilities
      @compatibilities ||= compatibility_criteria.map do |criterion|
        [
          criterion,
          Hash.new do |compatibilities, player|
            compatibilities[player] =
              compatible?(player) &&
              PlayerCompatibility.new(self, player).send("#{criterion}?")
          end
        ]
      end.to_h
    end

    def compatible?(player)
      !opponents.include?(player) && player.id != id
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
