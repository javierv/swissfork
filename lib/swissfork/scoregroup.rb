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
      if last?
        bracket.mark_byes_as_forbidden_downfloats
        return nil if leftovers.count > 1
      else
        bracket.number_of_required_downfloats = number_of_required_downfloats
        bracket.forbidden_downfloats = forbidden_downfloats

        until(bracket.pairs && next_scoregroup_pairing_is_ok?)
          # Criteria C.7
          if bracket.pairs.to_a.empty?
            reduce_number_of_next_scoregroup_required_pairs
            bracket.reset_impossible_downfloats
          else
            bracket.mark_established_downfloats_as_impossible
          end
        end
      end

      bracket.pairs
    end

    def number_of_required_downfloats
      number = Completion.new(remaining_players).number_of_required_mdps

      if number.odd? && players.count.even? || number.even? && players.count.odd?
        number + 1
      else
        number
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

    def forbidden_downfloats
      @forbidden_downfloats ||= players.combination(bracket.number_of_required_downfloats).select do |players|
        !Completion.new(remaining_players + players).ok?
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

    def hypothetical_next_players
      leftovers + next_scoregroup.players
    end

    def hypothetical_next_pairs
      Bracket.for(hypothetical_next_players).tap do |bracket|
        if next_scoregroup.last?
          bracket.mark_byes_as_forbidden_downfloats
        end
      end.pairs
    end

    def hypothetical_remaining_players
      remaining_players + leftovers
    end

    def next_scoregroup_pairing_is_ok?
      Completion.new(hypothetical_remaining_players).ok? &&
        hypothetical_next_pairs.to_a.count == number_of_next_scoregroup_required_pairs
    end

    def number_of_next_scoregroup_required_pairs
      @number_of_next_scoregroup_required_pairs ||= (bracket.number_of_required_downfloats + next_scoregroup.players.count) / 2
    end

    def reduce_number_of_next_scoregroup_required_pairs
      @number_of_next_scoregroup_required_pairs = number_of_next_scoregroup_required_pairs - 1
    end

    def remaining_players
      remaining_scoregroups.flat_map(&:players)
    end

    def remaining_scoregroups
      scoregroups[index+1..-1]
    end

    def scoregroups
      round.scoregroups
    end

    def reset
      @bracket = nil
    end
  end
end
