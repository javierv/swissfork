require "simple_initialize"
require "swissfork/bracket"

module Swissfork
  # Holds information about a bracket and the rest of the
  # scoregroups we need to pair.
  #
  # Sometimes a bracket needs to know about other brackets;
  # for example, in criterias C.4 (penultimate bracket) and
  # C.7 (maximize pairs in the next bracket).
  class Scoregroup
    require "swissfork/penultimate_bracket_handler"

    initialize_with :players, :round
    include Comparable

    def add_player(player)
      @bracket = nil
      @players = (players + [player]).sort
    end

    def add_players(players)
      players.each { |player| add_player(player) }
    end

    def remove_players(players_to_remove)
      @bracket = nil
      @players = players.reject { |player| players_to_remove.include?(player) }
    end

    def points
      players.map(&:points).min
    end

    def <=>(scoregroup)
      scoregroup.points <=> points
    end

    def pairs
      if bracket.heterogeneous? && !last?
        move_unpairable_moved_down_players_to_limbo
      end

      if penultimate?
        if next_scoregroup_pairing_is_ok?
          bracket.pairs
        else
          handler.move_players_to_allow_last_bracket_pairs && bracket.pairs
        end
      else
        bracket.pairs
      end
    end

    # This is an approach to detect the Collapsed Last Bracket.
    # TODO: While ideally we would call this method every time bracket.pairs
    # isn't empty, this would make the program many times slower.
    def impossible_to_pair?
      remaining_pairs.count < remaining_players.count / 2
    end

    def bracket
      @bracket ||= Bracket.for(players)
    end

    def leftovers
      limbo + bracket.leftovers.to_a
    end

    def move_leftovers_to_next_scoregroup
      next_scoregroup.add_players(leftovers)
      remove_players(leftovers)
    end

    def mark_established_pairs_as_impossible
      bracket.mark_established_pairs_as_impossible
    end

    def last?
      self == scoregroups.last
    end

    def pair_numbers
      pairs.map(&:numbers)
    end

    def leftover_numbers
      leftovers.map(&:number)
    end

  private
    def move_unpairable_moved_down_players_to_limbo
      limbo.push(*unpairable_moved_down_players)
      remove_players(unpairable_moved_down_players)
    end

    def unpairable_moved_down_players
      bracket.unpairable_moved_down_players
    end

    def next_scoregroup
      scoregroups[next_scoregroup_index]
    end

    def index
      scoregroups.index(self)
    end

    def next_scoregroup_index
       index + 1
    end

    def penultimate?
      scoregroups.count > 1 && self == scoregroups[-2]
    end

    def handler
      PenultimateBracketHandler.new(self, next_scoregroup)
    end

    def hypothetical_next_pairs
      Bracket.for(leftovers + next_scoregroup.players).pairs
    end

    def next_scoregroup_pairing_is_ok?
      hypothetical_next_pairs && !hypothetical_next_pairs.empty?
    end

    def remaining_pairs
      Bracket.for(remaining_players).pairs
    end

    def remaining_scoregroups
      scoregroups[index..-1]
    end

    def remaining_players
      remaining_scoregroups.map(&:players).flatten
    end

    def limbo
      @limbo ||= []
    end

    def scoregroups
      round.scoregroups
    end
  end
end
