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

    describe "#colour_violations" do
      let(:players) { create_players(1..10) }

      context "more players prefer one colour" do
        before(:each) do
          players[0..5].each_stub_preference(:white)
          players[6..9].each_stub_preference(:black)
        end

        it "calculates colour violations normally" do
          quality_calculator.colour_violations.should == 1
        end

        context "downfloats required" do
          before(:each) do
            quality_calculator.required_downfloats = 2
          end

          it "doesn't count the downfloats as violations" do
            quality_calculator.colour_violations.should == 0
          end
        end
      end

      context "a player can only be paired with players with the same colour" do
        context "with 10 players" do
          before(:each) do
            players[0..4].each_stub_preference(:white)
            players[5..9].each_stub_preference(:black)
            players[0].stub_opponents(players[5..9])
            players[5..9].each_stub_opponents([players[0]])
          end

          it "makes two pairs incompatible" do
            quality_calculator.colour_violations.should == 2
          end
        end
      end
    end

  end
end
