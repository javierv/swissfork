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
      return nil if impossible_to_pair?

      if last?
        if players.count.odd?
          bracket.number_of_required_downfloats = 1
          bracket.mark_as_forbidden_downfloats(byes)
        end

        reduce_pair_requirements until(bracket.pairs) # Needed for heterogeneous.
        return nil if bracket.leftovers.count > 1
      else
        until(bracket.pairs && next_scoregroup_pairing_is_ok?)
          if penultimate?
            bracket.mark_as_forbidden_downfloats(forbidden_downfloats)
            bracket.number_of_required_downfloats = number_of_required_downfloats
          end

          if bracket.pairs.to_a.empty?
            reduce_pair_requirements
          else
            mark_established_downfloats_as_impossible
          end
        end
      end

      bracket.pairs
    end

    # Detects the Collapsed Last Bracket.
    def impossible_to_pair?
      !remaining_bracket.all_players_can_be_paired? ||
        !remaining_bracket.bye_can_be_selected?
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

    def forbidden_downfloats
      @forbidden_downfloats ||= players.select do |player|
        player.compatible_players_in(next_scoregroup.players).none?
      end
    end

    def byes
      @byes ||= players.select(&:had_bye?)
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

    def hypothetical_remaining_players
      remaining_players - bracket.paired_players
    end

    def hypothetical_remaining_bracket
      Bracket.for(hypothetical_remaining_players)
    end

    def next_scoregroup_pairing_is_ok?
      hypothetical_next_pairs.to_a.count == number_of_next_scoregroup_required_pairs &&
        hypothetical_remaining_bracket.all_players_can_be_paired? && hypothetical_remaining_bracket.bye_can_be_selected?
    end

    # Applies criterias C.4, C.5 and C.7.
    def reduce_pair_requirements
      if penultimate? || last? || number_of_next_scoregroup_required_pairs.zero?
        reset_number_of_next_scoregroup_required_pairs
        bracket.reduce_number_of_required_pairs
      else
        bracket.reset_impossible_downfloats
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

    def remaining_bracket
      Bracket.for(remaining_players)
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
    end
  end
end
