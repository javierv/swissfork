require "spec_helper"
require "swissfork/colour_incompatibilities"
require "swissfork/player"

module Swissfork
  describe ColourIncompatibilities do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    describe "#violations" do
      let(:incompatibilities) { ColourIncompatibilities.new(players, number_of_possible_pairs) }
      let(:players) { create_players(1..10) }
      let(:number_of_possible_pairs) { 5 }

      context "no incompatibilities" do
        before(:each) do
          players[0..4].each { |player| player.stub_preference(:white) }
          players[5..9].each { |player| player.stub_preference(:black) }
        end

        it "returns zero" do
          incompatibilities.violations.should == 0
        end
      end

      context "two more players have one colour priority" do
        before(:each) do
          players[0..5].each { |player| player.stub_preference(:white) }
          players[6..9].each { |player| player.stub_preference(:black) }
        end

        it "returns one" do
          incompatibilities.violations.should == 1
        end

        context "not all pairings are possible" do
          let(:number_of_possible_pairs) { 4 }

          it "returns zero" do
            incompatibilities.violations.should == 0
          end
        end

        context "one player has no colour priority" do
          before(:each) { players[5].stub_preference(nil) }

          it "returns zero" do
            incompatibilities.violations.should == 0
          end
        end
      end
    end
  end
end
