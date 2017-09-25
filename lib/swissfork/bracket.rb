require "swissfork/players_difference"
require "swissfork/pair"

module Swissfork
  class Bracket
    require "swissfork/heterogeneous_bracket"

    include Comparable
    attr_reader :players

    def initialize(players)
      @players = players.sort
    end

    def add_player(player)
      @players = (players << player).sort
      @s1, @s2 = nil
    end

    def add_players(players)
      players.each { |player| add_player(player) }
    end

    def move_leftover_players_to(bracket)
      bracket.add_players(leftover_players)
      players.reject! { |player| leftover_players.include?(player) }
    end

    def move_players_to_allow_pairs_for(bracket)
      number_of_players = bracket.leftover_players.count

      if(number_of_players > 1)
        moved_players = players[(-1 * number_of_players)..-1]
        bracket.add_players(moved_players)
        players.reject! { |player| moved_players.include?(player) }
      end
    end

    def numbers
      players.map(&:number)
    end

    def points
      players.map(&:points).min
    end

    def <=>(bracket)
      bracket.points <=> points
    end

    def homogeneous?
      all_players_have_the_same_points? || half_or_more_players_were_descended?
    end

    def heterogeneous?
      !homogeneous?
    end

    def maximum_number_of_pairs
      players.length / 2
    end
    alias_method :p0, :maximum_number_of_pairs # FIDE nomenclature

    def number_of_descended_players
      @number_of_descended_players ||= descended_players.length
    end
    alias_method :m0, :number_of_descended_players # FIDE nomenclature

    def possible_number_of_pairs
      maximum_number_of_pairs
    end
    alias_method :p1, :possible_number_of_pairs # FIDE nomenclature

    def pairable_descended_players
      number_of_descended_players
    end
    alias_method :m1, :pairable_descended_players # FIDE nomenclature

    def number_of_required_pairs
      if homogeneous?
        possible_number_of_pairs
      else
        pairable_descended_players
      end
    end
    alias_method :p, :number_of_required_pairs # FIDE nomenclature

    def s1
      players[0..number_of_required_pairs-1].sort
    end

    def s2
      (players - s1).sort
    end

    def s1_numbers
      s1.map(&:number)
    end

    def s2_numbers
      s2.map(&:number)
    end

    def pairs
      if heterogeneous?
        HeterogeneousBracket.new(players).pairs
      else
        homogeneous_pairs
      end
    end

    def homogeneous_pairs
      while(!current_exchange_pairs)
        if exchange_count >= differences.count
          if failure_criterias.empty?
            return []
          else
            failure_criterias.pop
            restart_pairs
            players.sort!
          end
        else
          exchange
          restart_pairs
        end
      end

      current_exchange_pairs
    end

    def exchange
      players.sort!

      @players = exchanged_players(players, differences[exchange_count].s1_player, differences[exchange_count].s2_player)
      @exchange_count += 1
    end

    # Helper method which makes tests more readable.
    def pair_numbers
      pairs.map(&:numbers)
    end

    def leftover_players
      @leftover_players ||= unpaired_players_after(pairs)
    end

    def mark_established_pairs_as_impossible
      impossible_pairs << established_pairs
      clear_established_pairs
    end

  private
    def players_with(numbers)
      numbers.map { |number| player_with(number) }
    end

    def player_with(number)
      players.select { |player| player.number == number }.first
    end

    def differences
      s1.product(s2).map do |players|
        PlayersDifference.new(*players)
      end.sort
    end

    def current_exchange_pairs
      return definitive_pairs if @bracket_already_paired
      clear_established_pairs

      while(!pairings_completed?)
        establish_pairs
        return nil if established_pairs.empty?

        if best_pairs_obtained?
          @bracket_already_paired = true
          return definitive_pairs
        else
          mark_established_pairs_as_impossible
        end
      end
    end

    def establish_pairs
      s1.each do |player|
        pair = pair_for(player)
        if pair
          return nil unless still_unpaired_players_can_downfloat?
          established_pairs << pair
        else
          return nil
        end
      end
    end

    def still_unpaired_players_can_downfloat?
      still_unpaired_s2_players.any? do |unpaired_player|
        possible_downfloaters.include?(unpaired_player)
      end
    end

    def possible_downfloaters
      players.select do |player|
        !(
          failure_criterias.include?(:same_downfloats_as_previous_round?) &&
          player.descended_in_the_previous_round?
        ) && !(
          failure_criterias.include?(:same_downfloats_as_two_rounds_ago?) &&
          player.descended_two_rounds_ago?
        )
      end
    end

    def best_pairs_obtained?
      pairings_completed? && best_possible_pairs?
    end

    def definitive_pairs
      established_pairs
    end

    def pair_for(s1_player)
      players_for(s1_player).map  { |s2_player| Pair.new(s1_player, s2_player) }.select do |pair|
        !impossible_pairs.include?(established_pairs + [pair])
      end.first
    end

    def players_for(s1_player)
      s2.select do |s2_player|
        s1_player.compatible_with?(s2_player) && !already_paired?(s2_player)
      end
    end

    def pairings_completed?
      established_pairs.count == s1.count
    end

    def exchanged_players(players, player1, player2)
      index1, index2 = players.index(player1), players.index(player2)

      players.dup.tap do |new_players|
        new_players[index1], new_players[index2] = player2, player1
      end
    end

    def exchange_count
      @exchange_count ||= 0
    end

    def established_pairs
      @established_pairs ||= []
    end

    def clear_established_pairs
      @established_pairs = []
      @bracket_already_paired = false
    end

    def impossible_pairs
      @impossible_pairs ||= []
    end

    def restart_pairs
      @impossible_pairs = []
      clear_established_pairs
    end

    def already_paired?(player)
      established_pairs.any? { |pair| pair.include?(player) }
    end

    def still_unpaired_players
      unpaired_players_after(established_pairs)
    end

    def still_unpaired_s2_players
      s2 & still_unpaired_players
    end

    def unpaired_players_after(pairs)
      players - (pairs.map(&:s1_player) + pairs.map(&:s2_player))
    end

    def all_players_have_the_same_points?
      players.map(&:points).uniq.one?
    end

    def half_or_more_players_were_descended?
      number_of_descended_players >= players.length / 2
    end

    def descended_players
      players.select { |player| player.points > points }
    end

    def best_possible_pairs?
      failure_criterias.none? { |condition| send(condition) }
    end

    def failure_criterias
      @failure_criterias ||= [
        :any_players_descending_twice?,
        :same_downfloats_as_previous_round?,
        :same_upfloats_as_previous_round?,
        :same_downfloats_as_two_rounds_ago?,
        :same_upfloats_as_two_rounds_ago?
      ]
    end

    def any_players_descending_twice?
      still_unpaired_players.any? do |player|
        player.points > points
      end
    end

    def same_downfloats_as_previous_round?
      still_unpaired_players.any? do |player|
        player.descended_in_the_previous_round?
      end
    end

    def same_upfloats_as_previous_round?
      ascending_players.any? do |player|
        player.ascended_in_the_previous_round?
      end
    end

    def same_downfloats_as_two_rounds_ago?
      still_unpaired_players.any? do |player|
        player.descended_two_rounds_ago?
      end
    end

    def same_upfloats_as_two_rounds_ago?
      ascending_players.any? do |player|
        player.ascended_two_rounds_ago?
      end
    end

    def ascending_players
      heterogeneous_pairs.map(&:s2_player)
    end

    def heterogeneous_pairs
      established_pairs.select do |pair|
        pair.s1_player.points != pair.s2_player.points
      end
    end
  end
end
