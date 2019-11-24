require "spec_helper"
require "swissfork/no_preference_incompatibilities"
require "swissfork/player"

module Swissfork
  describe NoPreferenceIncompatibilities do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    let(:incompatibilities) { NoPreferenceIncompatibilities.new(players) }
    let(:players) { create_players(1..10) }
    let(:number_of_required_pairs) { 5 }

    describe "#violations_for" do
      context "no players with no preference" do
        before { players.each_stub_preference(:white) }

        it "returns zero" do
          incompatibilities.violations_for(:white).should eq 0
          incompatibilities.violations_for(:black).should eq 0
        end
      end

      context "same number of players with each preference" do
        before do
          players[0..3].each_stub_preference(:white)
          players[4..7].each_stub_preference(:black)
          players[8..9].each_stub_preference(nil)
        end

        it "returns half the players with no preference" do
          incompatibilities.violations_for(:white).should eq 1
          incompatibilities.violations_for(:black).should eq 1
        end

        context "odd number of players" do
          let(:players) { create_players(1..11) }
          before { players[8..10].each_stub_preference(nil) }

          it "returns half the players with no preference, rounding up" do
            incompatibilities.violations_for(:white).should eq 2
            incompatibilities.violations_for(:black).should eq 2
          end
        end

        context "most players have no preference" do
          before do
            players[0..1].each_stub_preference(:white)
            players[2..3].each_stub_preference(:black)
            players[4..9].each_stub_preference(nil)
          end

          it "returns the number of players with the colour preference" do
            incompatibilities.violations_for(:white).should eq 2
            incompatibilities.violations_for(:black).should eq 2
          end
        end
      end

      context "more players with one preference" do
        context "one player with no preference" do
          before do
            players[0..4].each_stub_preference(:white)
            players[5..8].each_stub_preference(:black)
            players[9].stub_preference(nil)
          end

          it "returns one for the main preference" do
            incompatibilities.violations_for(:white).should eq 1
          end

          it "returns zero for the minoritary preference" do
            incompatibilities.violations_for(:black).should eq 0
          end
        end

        context "three players with no preference" do
          context "colour difference is one" do
            before do
              players[0..3].each_stub_preference(:white)
              players[4..6].each_stub_preference(:black)
              players[7..9].each_stub_preference(nil)
            end

            it "can pair one player with the minoritary difference" do
              incompatibilities.violations_for(:white).should eq 2
              incompatibilities.violations_for(:black).should eq 1
            end
          end

          context "colour difference is two" do
            let(:players) { create_players(1..11) }

            before do
              players[0..4].each_stub_preference(:white)
              players[5..7].each_stub_preference(:black)
              players[8..10].each_stub_preference(nil)
            end

            it "can pair player all players the main preference" do
              incompatibilities.violations_for(:white).should eq 3
            end

            it "or it can pair one player with the minoritary preference" do
              incompatibilities.violations_for(:black).should eq 1
            end
          end
        end

        context "four players with no preference" do
          context "colour difference is two" do
            before do
              players[0..3].each_stub_preference(:white)
              players[4..5].each_stub_preference(:black)
              players[6..9].each_stub_preference(nil)
            end

            it "can pair one player with the minoritary preference" do
              incompatibilities.violations_for(:white).should eq 3
              incompatibilities.violations_for(:black).should eq 1
            end
          end

          context "colour difference is three" do
            let(:players) { create_players(1..11) }

            before do
              players[0..4].each_stub_preference(:white)
              players[5..6].each_stub_preference(:black)
              players[7..10].each_stub_preference(nil)
            end

            it "can pair all players with the main preference" do
              incompatibilities.violations_for(:white).should eq 4
            end

            it "or it can pair one player with the minoritary preference" do
              incompatibilities.violations_for(:black).should eq 1
            end
          end
        end
      end
    end
  end
end
