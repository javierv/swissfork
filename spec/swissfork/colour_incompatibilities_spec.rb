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

    describe "#strong_violations" do
      context "no incompatibilities" do
        before(:each) do
          players[0..4].each_stub_preference(:white)
          players[5..9].each_stub_preference(:black)
        end

        it "returns zero" do
          incompatibilities.strong_violations.should == 0
        end
      end

      context "two more players have one colour priority" do
        before(:each) do
          players[0..5].each_stub_preference(:white)
          players[6..9].each_stub_preference(:black)
        end

        it "returns the number of violations" do
          incompatibilities.strong_violations.should == 1
        end

        context "one player has a mild preference" do
          before(:each) { players[5].stub_degree(:mild) }

          it "returns zero" do
            incompatibilities.strong_violations.should == 0
          end

          context "that player can't be paired with players with the same colour" do
            before(:each) do
              players[5].stub_opponents(players[0..4])
              players[0..4].each_stub_opponents([players[5]])
            end

            it "needs to violate one strong preference" do
              incompatibilities.strong_violations.should == 1
            end
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

    describe "#no_preference_violations_for" do
      context "no players with no preference" do
        before(:each) { players.each_stub_preference(:white) }

        it "returns zero" do
          incompatibilities.no_preference_violations_for(:white).should == 0
          incompatibilities.no_preference_violations_for(:black).should == 0
        end
      end

      context "same number of players with each preference" do
        before(:each) do
          players[0..3].each_stub_preference(:white)
          players[4..7].each_stub_preference(:black)
          players[8..9].each_stub_preference(nil)
        end

        it "returns half the players with no preference" do
          incompatibilities.no_preference_violations_for(:white).should == 1
          incompatibilities.no_preference_violations_for(:black).should == 1
        end

        context "odd number of players" do
          let(:players) { create_players(1..11) }
          before(:each) { players[8..10].each_stub_preference(nil) }

          it "returns half the players with no preference, rounding up" do
            incompatibilities.no_preference_violations_for(:white).should == 2
            incompatibilities.no_preference_violations_for(:black).should == 2
          end
        end

        context "most players have no preference" do
          before(:each) do
            players[0..1].each_stub_preference(:white)
            players[2..3].each_stub_preference(:black)
            players[4..9].each_stub_preference(nil)
          end

          it "returns the number of players with the colour preference" do
            incompatibilities.no_preference_violations_for(:white).should == 2
            incompatibilities.no_preference_violations_for(:black).should == 2
          end
        end
      end

      context "more players with one preference" do
        context "one player with no preference" do
          before(:each) do
            players[0..4].each_stub_preference(:white)
            players[5..8].each_stub_preference(:black)
            players[9].stub_preference(nil)
          end

          it "returns one for the main preference" do
            incompatibilities.no_preference_violations_for(:white).should == 1
          end

          it "returns zero for the minoritary preference" do
            incompatibilities.no_preference_violations_for(:black).should == 0
          end
        end

        context "three players with no preference" do
          context "colour difference is one" do
            before(:each) do
              players[0..3].each_stub_preference(:white)
              players[4..6].each_stub_preference(:black)
              players[7..9].each_stub_preference(nil)
            end

            it "can pair one player with the minoritary difference" do
              incompatibilities.no_preference_violations_for(:white).should == 2
              incompatibilities.no_preference_violations_for(:black).should == 1
            end
          end

          context "colour difference is two" do
            let(:players) { create_players(1..11) }

            before(:each) do
              players[0..4].each_stub_preference(:white)
              players[5..7].each_stub_preference(:black)
              players[8..10].each_stub_preference(nil)
            end

            it "can pair player all players the main preference" do
              incompatibilities.no_preference_violations_for(:white).should == 3
            end

            it "or it can pair one player with the minoritary preference" do
              incompatibilities.no_preference_violations_for(:black).should == 1
            end
          end
        end

        context "four players with no preference" do
          context "colour difference is two" do
            before(:each) do
              players[0..3].each_stub_preference(:white)
              players[4..5].each_stub_preference(:black)
              players[6..9].each_stub_preference(nil)
            end

            it "can pair one player with the minoritary preference" do
              incompatibilities.no_preference_violations_for(:white).should == 3
              incompatibilities.no_preference_violations_for(:black).should == 1
            end
          end

          context "colour difference is three" do
            let(:players) { create_players(1..11) }

            before(:each) do
              players[0..4].each_stub_preference(:white)
              players[5..6].each_stub_preference(:black)
              players[7..10].each_stub_preference(nil)
            end

            it "can pair all players with the main preference" do
              incompatibilities.no_preference_violations_for(:white).should == 4
            end

            it "or it can pair one player with the minoritary preference" do
              incompatibilities.no_preference_violations_for(:black).should == 1
            end
          end
        end
      end
    end
  end
end
