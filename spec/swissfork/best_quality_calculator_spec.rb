require "create_players_helper"
require "swissfork/best_quality_calculator"

module Swissfork
  describe BestQualityCalculator do
    let(:quality_calculator) { BestQualityCalculator.new(players) }

    describe "#pairs_after_downfloats" do
      context "even number of players" do
        let(:players) { create_players(1..6) }

        it "returns half of the number of players" do
          quality_calculator.pairs_after_downfloats.should == 3
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..7) }

        it "returns half of the number of players rounded downwards" do
          quality_calculator.pairs_after_downfloats.should == 3
        end
      end
    end
  end
end
