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
    initialize_with :players, :round
    include Comparable

    def add_player(player)
      reset
      @players = (players + [player]).sort
    end

    def add_players(players)
      players.each { |player| add_player(player) }
    end

    def remove_players(players_to_remove)
      reset
      @players = players.reject { |player| players_to_remove.include?(player) }
    end

    def points
      bracket.points
    end

    def <=>(scoregroup)
      bracket <=> scoregroup.bracket
    end

    def pairs
      return nil if (penultimate? || last?) && impossible_to_pair?

      unless last?
        mark_impossible_downfloats_as_impossible

        until(bracket.pairs && next_scoregroup_pairing_is_ok?)
          return nil if bracket.number_of_required_pairs.zero?

          if penultimate?
            bracket.number_of_required_downfloats = number_of_required_downfloats
          end

          if bracket.pairs
            mark_established_downfloats_as_impossible
          else
            reduce_pair_requirements
          end
        end
      end

      bracket.pairs
    end

    # This is an approach to detect the Collapsed Last Bracket.
    # TODO: While ideally we would call this method every time bracket.pairs
    # isn't empty, this would make the program many times slower.
    def impossible_to_pair?
      remaining_pairs.count < remaining_players.count / 2
    end

    def number_of_required_downfloats
      all_players = players + next_scoregroup.players

      if all_players.count.odd?
        if next_scoregroup.players.count.even?
          next_scoregroup.leftovers.count + 1
        else
          next_scoregroup.leftovers.count - 1
        end
      else
        next_scoregroup.leftovers.count
      end
    end

    def bracket
      @bracket ||= Bracket.for(players)
    end

    def leftovers
      bracket.leftovers.to_a
    end

    def move_leftovers_to_next_scoregroup
      next_scoregroup.add_players(leftovers)
      remove_players(leftovers)
    end

    def mark_established_downfloats_as_impossible
      bracket.mark_established_downfloats_as_impossible
    end

    def mark_impossible_downfloats_as_impossible
      bracket.mark_as_impossible_downfloats(impossible_downfloats)
    end

    def impossible_downfloats
      @impossible_downfloats ||= players.select do |player|
        player.compatible_players_in(next_scoregroup.players).none?
      end
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

    def hypothetical_next_players
      leftovers + next_scoregroup.players
    end

    def hypothetical_next_pairs
      Bracket.for(hypothetical_next_players).pairs
    end

    def next_scoregroup_pairing_is_ok?
      hypothetical_next_pairs.to_a.count == number_of_next_scoregroup_required_pairs
    end

    # Applies criterias C.4, C.5, C.6 and C.7.
    def reduce_pair_requirements
      if penultimate? || number_of_next_scoregroup_required_pairs.zero?
        reset_number_of_next_scoregroup_required_pairs
        bracket.reduce_number_of_required_pairs
      else
        bracket.impossible_downfloats = impossible_downfloats
        reduce_number_of_next_scoregroup_required_pairs
      end
    end

    def number_of_next_scoregroup_required_pairs
      @number_of_next_scoregroup_required_pairs || hypothetical_next_players.count / 2
    end

    def reduce_number_of_next_scoregroup_required_pairs
      @number_of_next_scoregroup_required_pairs = number_of_next_scoregroup_required_pairs - 1
    end

    def reset_number_of_next_scoregroup_required_pairs
      @number_of_next_scoregroup_required_pairs = nil
    end

    def remaining_pairs
      # We use homogeneous brackets here because they're easier to pair.
      @remaining_pairs ||= HomogeneousBracket.new(remaining_players).pairs
    end

    def remaining_scoregroups
      scoregroups[index..-1]
    end

    def remaining_players
      remaining_scoregroups.flat_map(&:players)
    end

    def scoregroups
      round.scoregroups
    end

    def reset
      @bracket = nil
      @remaining_pairs = nil
    end
  end
end
