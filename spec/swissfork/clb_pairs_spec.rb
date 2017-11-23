require "create_players_helper"
require "swissfork/round"

module Swissfork
  describe Round do
    let(:round) { Round.new(players) }

    describe "#pairs when the last bracket can't be paired" do
      let(:players) { create_players(1..10) }

      before(:each) do
        players[0..7].each_stub(points: 1)
        players[8..9].each_stub(points: 0)
      end

      context "last players from the PPB complete the pairing" do
        before(:each) do
          players[8].stub_opponents([players[9]])
          players[9].stub_opponents([players[8]])
        end

        it "descends players from the previous bracket" do
          round.pair_numbers.should eq [[1, 4], [2, 5], [3, 6], [7, 9], [8, 10]]
        end
      end

      context "last players from the PPB complete the pairing, but shouldn't downfloat" do
        before(:each) do
          players[8].stub_opponents([players[9]])
          players[9].stub_opponents([players[8]])
          players[7].stub(floats: [:down])
        end

        it "descends players who may downfloat" do
          round.pair_numbers.should eq [[1, 4], [2, 5], [3, 8], [6, 9], [7, 10]]
        end
      end

      context "last players from the PPB don't complete the pairing" do
        before(:each) do
          players[5].stub_opponents([players[8], players[9]])
          players[6].stub_opponents([players[8]])
          players[7].stub_opponents([players[8]])
          players[8].stub_opponents(players[5..9])
          players[9].stub_opponents([players[5], players[8]])
        end

        it "descends a different set of players" do
          round.pair_numbers.should eq [[1, 4], [2, 6], [3, 7], [5, 9], [8, 10]]
        end
      end

      context "no players from the PPB complete the pairing" do
        before(:each) do
          players[0..1].each_stub(points: 2)
          players[2..7].each_stub_opponents([players[8], players[9]])
          players[8..9].each_stub_opponents(players[2..9])
        end

        it "redoes the pairing of the last paired bracket" do
          round.pair_numbers.should eq [[1, 9], [2, 10], [3, 6], [4, 7], [5, 8]]
        end

        context "the last bracket has some pairable players" do
          before(:each) do
            players[6..7].each_stub(points: 0)
          end

          it "pairs those players against each other" do
            round.pair_numbers.should eq [[1, 9], [2, 10], [3, 5], [4, 6], [7, 8]]
          end
        end

        context "the last paired bracket has more players than downfloaters" do
          before(:each) do
            players[2..3].each_stub(points: 2)
            players[2..3].each_stub_opponents([])
            players[8..9].each_stub_opponents(players[4..9])
          end

          it "downfloats only the needed players" do
            round.pair_numbers.should eq [[1, 2], [3, 9], [4, 10], [5, 7], [6, 8]]
          end
        end
      end

      context "PPB has leftovers and last bracket has incompatible players" do
        let(:players) { create_players(1..11) }

        before(:each) do
          players[0..8].each_stub(points: 1)
          players[9..10].each_stub(points: 0)
          players[9].stub_opponents([players[10]])
          players[10].stub_opponents([players[9]])
        end

        it "pairs normally, using the leftovers " do
          round.pair_numbers.should eq [[1, 5], [2, 6], [3, 7], [4, 8], [9, 10]]
        end
      end

      context "many brackets, PPB + last bracket can't be paired" do
        let(:players) { create_players(1..12) }

        before(:each) do
          players[0..1].each_stub(points: 3)
          players[2..5].each_stub(points: 2)
          players[6..9].each_stub(points: 1)
          players[9..11].each_stub(points: 0)
          players[7..8].each_stub_opponents(players[9..11])
          players[9..11].each_stub_opponents(players[7..11])
        end

        it "downfloats players from previous brackets" do
          round.pair_numbers.should eq [[1, 2], [3, 4], [5, 10], [6, 11], [8, 9], [7, 12]]
        end
      end

      context "Only remainder players can complete the PPB + last bracket" do
        let(:players) { create_players(1..8) }

        before(:each) do
          players[0].stub(points: 3)
          players[1..3].each_stub(points: 2)
          players[4..5].each_stub(points: 1)
          players[6..7].each_stub(points: 0)
          players[4..5].each_stub_opponents(players[6..7])
          players[6..7].each_stub_opponents(players[4..7])
        end

        it "pairs the MDP and downfloats players from the remainder" do
          round.pair_numbers.should eq [[1, 2], [3, 7], [4, 8], [5, 6]]
        end
      end

      context "a combinations of MDPs and remainders complete the pairing" do
        let(:players) { create_players(1..10) }

        before(:each) do
          # The first two brackets will be merged as one; its pairing is the
          # one we're testing.
          players[0..1].each_stub(points: 3)
          players[2..5].each_stub(points: 2)
          players[6..9].each_stub(points: 1)

          players[0..1].each_stub_opponents(players[0..1])
          players[5].stub_opponents(players[6..9])
          players[6..9].each_stub_opponents([players[5]] + players[6..9])
        end

        it "maximizes number of pairs, then number of MDP pairs" do
          round.pair_numbers.should eq [[1, 6], [2, 7], [3, 8], [4, 9], [5, 10]]
        end
      end
    end
  end
end
