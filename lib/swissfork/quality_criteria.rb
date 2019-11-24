require "simple_initialize"

module Swissfork
  # Stores which quality criterion failed and
  # modifies the allowed failures when no candidate
  # meeting the allowed failures can be found
  class QualityCriteria
    initialize_with :bracket

    def ok?
      if quality_checker.ok?
        true
      else
        failing_criteria << failing_criterion
        false
      end
    end

    def failing_criterion
      quality_checker.failing_criterion(criteria)
    end

    def be_more_permissive
      relevant_criterion = current_failing_criterion

      if relevant_criterion != old_failing_criterion
        if old_failing_criterion_is_less_important?
          allowed_failures[old_failing_criterion] = 0
        end

        self.old_failing_criterion = relevant_criterion
      end

      quality_calculator.reset_failing_criteria
      allowed_failures[relevant_criterion] += 1
    end

    private

      def failing_criteria
        quality_calculator.failing_criteria
      end

      def current_failing_criterion
        if ok?
          failing_criteria.sort_by { |criterion| criteria.index(criterion) }.last
        else
          failing_criterion
        end
      end

      def old_failing_criterion_is_less_important?
        if old_failing_criterion
          criteria.index(old_failing_criterion) > criteria.index(current_failing_criterion)
        else
          true
        end
      end

      attr_accessor :old_failing_criterion

      def allowed_failures
        quality_calculator.allowed_failures
      end

      def quality_checker
        QualityChecker.new(bracket.provisional_pairs, bracket.provisional_leftovers,
                           quality_calculator)
      end

      def criteria
        QualityChecker.criteria
      end

      def quality_calculator
        bracket.quality_calculator
      end
  end
end
