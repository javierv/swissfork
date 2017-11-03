require "spec_helper"
require "swissfork/colour_incompatibilities"
require "swissfork/player"

module Swissfork
  describe ColourIncompatibilities do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    let(:incompatibilities) { ColourIncompatibilities.new(players, number_of_required_pairs) }
    let(:players) { create_players(1..10) }
    let(:number_of_required_pairs) { 5 }

    describe "#violations" do
      context "no incompatibilities" do
        before(:each) do
          players[0..4].each_stub_preference(:white)
          players[5..9].each_stub_preference(:black)
        end

        it "returns zero" do
          incompatibilities.violations.should == 0
        end
      end

      context "two more players have one colour priority" do
        before(:each) do
          players[0..5].each_stub_preference(:white)
          players[6..9].each_stub_preference(:black)
        end

        it "returns one" do
          incompatibilities.violations.should == 1
        end

        context "not all pairings are possible" do
          let(:number_of_required_pairs) { 4 }

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

    describe "#main_preference" do
      context "all players prefer the same colour" do
        context "all prefer white" do
          before(:each) do
            players.each_stub_preference(:white)
          end

          it "returns the colour everybody prefers" do
            incompatibilities.main_preference.should == :white
          end
        end

        context "all prefer black" do
          before(:each) do
            players.each_stub_preference(:black)
          end

          it "returns the colour everybody prefers" do
            incompatibilities.main_preference.should == :black
          end
        end
      end
    end
  end
end
