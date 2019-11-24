require "spec_helper"
require "swissfork/colour_possible_pairs"
require "swissfork/player"

module Swissfork
  describe ColourPossiblePairs do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    describe "#count" do
      let(:pairs) { ColourPossiblePairs.new(players) }
      let(:players) { create_players(1..10) }

      context "no incompatibilities" do
        before do
          players[0..4].each_stub_preference(:white)
          players[5..9].each_stub_preference(:black)
        end

        it "returns the number of all possible pairs" do
          pairs.count.should eq 5
        end
      end

      context "two more players have one colour priority" do
        before do
          players[0..5].each_stub_preference(:white)
          players[6..9].each_stub_preference(:black)
        end

        it "returns one less than the possible number of pairs" do
          pairs.count.should eq 4
        end
      end

      context "not all pairings are possible" do
        before do
          players[0..1].each_stub_opponents(players[0..9])
          players[2..9].each_stub_opponents(players[0..1])
        end

        context "no incompatibilities" do
          it "returns the number of possible pairs" do
            pairs.count.should eq 4
          end
        end

        context "remaining players have different colour preference" do
          before do
            players[0..4].each_stub_preference(:white)
            players[5..9].each_stub_preference(:black)
          end

          it "marks one more pair as incompatible" do
            pairs.count.should eq 3
          end
        end

        context "a player can only be paired with players with the same colour" do
          before do
            players[0..4].each_stub_preference(:white)
            players[5..9].each_stub_preference(:black)
            players[0].stub_opponents(players[5..9])
            players[5..9].each_stub_opponents([players[0]])
          end

          it "makes two pairs incompatible" do
            pairs.count.should eq 3
          end
        end

        context "minimizing colour violations results in less total pairs" do
          before do
            # In theory, 1 can play against 10, and 6 can play against 5.
            # However, that would make the rest of the players impossible to pair.
            players[0..4].each_stub_preference(:white)
            players[5..9].each_stub_preference(:black)
            players[0..3].each_stub_opponents(players[5..8])
            players[5..8].each_stub_opponents(players[0..3])
          end

          it "returns the colour violations maximizing the number of pairs" do
            pairs.count.should eq 1
          end
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..5) }
        before do
          # Correct pairs: 3-5, 1-4, 2 downfloats
          players[0..1].each_stub_opponents([players[4]])
          players[4].stub_opponents(players[0..1])
          players[0..2].each_stub_preference(:white)
          players[3..4].each_stub_preference(:black)
        end

        it "ignores the player who will downfloat" do
          pairs.count.should eq 2
        end
      end
    end
  end
end
