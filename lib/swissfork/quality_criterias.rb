module Swissfork
  # Checks quality of pairs following the quality criterias
  # described in FIDE Dutch System, sections C.8 to C.19.
  #
  # Criterias C.5 to C.7 are implemented in the main algorithm.
  class QualityCriterias
    initialize_with :bracket

    def ok?
      criterias.none? { |condition| send(condition) }
    end

    def worst_possible?
      # TODO: change when we add support for colours.
      allowed_failures[criterias[0]] > number_of_required_downfloats + 1
    end

    def be_more_permissive
      failing_criteria = current_failing_criteria

      if failing_criteria != old_failing_criteria
        if old_failing_criteria_is_less_important?
          allowed_failures[old_failing_criteria] = 0
        end

        self.old_failing_criteria = failing_criteria
      end

      allowed_failures[failing_criteria] += 1
    end

    def can_downfloat?(leftovers)
      return true if number_of_required_downfloats.zero?

      leftovers.combination(number_of_required_downfloats).any? do |players|
        allowed_downfloats.include?(players.to_set) &&
          !exceed_same_downfloats_as_previous_round?(players) &&
          !exceed_same_downfloats_as_two_rounds_ago?(players)
      end
    end

  private
    attr_writer :old_failing_criteria

    def self.criterias
      [
        :same_downfloats_as_previous_round?,
        :same_upfloats_as_previous_round?,
        :same_downfloats_as_two_rounds_ago?,
        :same_upfloats_as_two_rounds_ago?
      ]
    end

    def criterias
      self.class.criterias
    end

    criterias.each do |criteria|
      define_method criteria do
        send(criteria.to_s.delete("?")).count > allowed_failures[criteria]
      end
    end

    def allowed_failures
      @allowed_failures ||= Hash.new(0)
    end

    # C.12
    def same_downfloats_as_previous_round
      pairable_leftovers.select { |player| player.descended_in_the_previous_round? }
    end

    # C.13
    def same_upfloats_as_previous_round
      ascending_players.select { |player| player.ascended_in_the_previous_round? }
    end

    # C.14
    def same_downfloats_as_two_rounds_ago
      pairable_leftovers.select { |player| player.descended_two_rounds_ago? }
    end

    # C.15
    def same_upfloats_as_two_rounds_ago
      ascending_players.select { |player| player.ascended_two_rounds_ago? }
    end

    def current_failing_criteria
      if ok? # HACK: hypothetical quality check in Bracket prevents pairings at all.
        if allowed_failures[:same_downfloats_as_two_rounds_ago?] >= number_of_required_downfloats
          :same_downfloats_as_previous_round?
        else
          :same_downfloats_as_two_rounds_ago?
        end
      else
        criterias.select { |condition| send(condition) }.last
      end
    end

    def old_failing_criteria
      @old_failing_criteria ||= criterias.last
    end

    def old_failing_criteria_is_less_important?
      criterias.index(old_failing_criteria) > criterias.index(current_failing_criteria)
    end

    def exceed_same_downfloats_as_previous_round?(players)
      players.reject(&:descended_in_the_previous_round?).count <
        number_of_downfloats_not_from_the_previous_round
    end

    def exceed_same_downfloats_as_two_rounds_ago?(players)
      players.reject do |player|
        player.descended_two_rounds_ago? &&
          !player.descended_in_the_previous_round?
      end.count < number_of_downfloats_not_from_two_rounds_ago
    end

    def number_of_downfloats_not_from_two_rounds_ago
      number_of_required_downfloats -
        allowed_failures[:same_downfloats_as_two_rounds_ago?]
    end

    def number_of_downfloats_not_from_the_previous_round
      number_of_required_downfloats -
        allowed_failures[:same_downfloats_as_previous_round?]
    end

    def ascending_players
      heterogeneous_pairs.map(&:last)
    end

    def heterogeneous_pairs
      pairs.select(&:heterogeneous?)
    end

    def pairable_leftovers
      bracket.pairable_hypothetical_leftovers
    end

    # TODO: this isn't very elegant.
    def pairs
      bracket.send(:established_pairs)
    end

    def number_of_required_downfloats
      bracket.number_of_required_downfloats
    end

    def allowed_downfloats
      bracket.allowed_downfloats
    end
  end
end
