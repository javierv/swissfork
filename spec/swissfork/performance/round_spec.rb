require "create_players_helper"
require "benchmark"
require "swissfork/round"
require "swissfork/player"

module Swissfork
  describe Round do
    let(:round) { Round.new(players) }

    context "no obvious downfloat" do
      context "18 players" do
        let(:players) { create_players(1..18) }

        before(:each) do
          players[0..8].each_stub(points: 1)
          players[4..8].each_stub(floats: [:down])
        end

        it "is very fast" do
          Benchmark.realtime { round.pair_numbers }.should be < 0.02
          round.pair_numbers.should eq [[1, 6], [2, 7], [3, 8], [5, 9], [4, 10], [11, 15], [12, 16], [13, 17], [14, 18]]
        end
      end

      context "50 players" do
        let(:players) { create_players(1..50) }

        before(:each) do
          players[0..24].each_stub(points: 1)
          players[12..24].each_stub(floats: [:down])
        end

        it "performs like O(n^2)" do
          Benchmark.realtime { round.pair_numbers }.should be < 0.1
          round.pair_numbers.should eq [
            [1, 14], [2, 15], [3, 16], [4, 17], [5, 18], [6, 19], [7, 20],
            [8, 21], [9, 22], [10, 23], [11, 24], [13, 25], [12, 26],
            [27, 39], [28, 40], [29, 41], [30, 42], [31, 43], [32, 44],
            [33, 45], [34, 46], [35, 47], [36, 48], [37, 49], [38, 50]
          ]
        end
      end

      context "150 players" do
        let(:players) { create_players(1..150) }

        before(:each) do
          players[0..74].each_stub(points: 1)
          players[37..74].each_stub(floats: [:down])
        end

        it "is very fast" do
          Benchmark.realtime { round.pair_numbers }.should be < 0.6
        end
      end
    end

    context "downfloats from two rounds ago need to repeat" do
      context "with 15 players" do
        let(:players) { create_players(1..15) }

        before(:each) do
          players[0..13].each_stub(floats: [:down])
          players[14].stub(floats: [:down, nil])
        end

        it "performs at a reasonable speed" do
          Benchmark.realtime { round.pair_numbers }.should be < 1.2
          round.pair_numbers.should eq [
            [1, 8], [2, 9], [3, 10], [4, 11], [5, 12], [6, 13], [7, 14]
          ]
        end
      end
    end

    context "homogeneous penultimate bracket; the last one can't be paired" do
      context "16 players, 4 of them in the last group" do
        let(:players) { create_players(1..16) }

        before(:each) do
          players[0..11].each_stub(points: 1)
          players[12..15].each_stub(points: 0)
        end

        context "the last 4 players in the first group can't downfloat" do
          before(:each) do
            players[8..11].each_stub_opponents(players[12..15])
            players[12..15].each_stub_opponents(players[8..15])
          end

          it "pairs fast" do
            Benchmark.realtime { round.pair_numbers }.should be < 0.5
            round.pair_numbers.should eq [[1, 9], [2, 10], [3, 11], [4, 12],
                                          [5, 13], [6, 14], [7, 15], [8, 16]]
          end
        end

        context "the last 6 players in the first group can't downfloat" do
          before(:each) do
            players[6..11].each_stub_opponents(players[12..15])
            players[12..15].each_stub_opponents(players[6..15])
          end

          it "pairs fast" do
            Benchmark.realtime { round.pair_numbers }.should be < 0.5
            round.pair_numbers.should eq [[1, 9], [2, 10], [7, 11], [8, 12], [3, 13], [4, 14], [5, 15], [6, 16]]
          end
        end
      end

      context "with 20 players; the last 7 in the first group can't downfloat" do
        let(:players) { create_players(1..20) }

        before(:each) do
          players[0..15].each_stub(points: 1)
          players[16..19].each_stub(points: 0)
          players[9..15].each_stub_opponents(players[16..19])
          players[16..19].each_stub_opponents(players[9..19])
        end

        it "isn't too slow" do
          Benchmark.realtime { round.pair_numbers }.should be < 1.3
          round.pair_numbers.should eq [[1, 11], [2, 12], [3, 13], [4, 14], [5, 15], [10, 16], [6, 17], [7, 18], [8, 19], [9, 20]]
        end
      end
    end

    context "PPB + last bracket can't be paired" do
      context "20 players, heterogeneous PPB, 4 players in the last bracket" do
        let(:players) { create_players(1..20) }

        before(:each) do
          players[0..5].each_stub(points: 3)
          players[6..11].each_stub(points: 2)
          players[12..15].each_stub(points: 1)
          players[16..19].each_stub(points: 0)
          players[13..15].each_stub_opponents(players[16..19])
          players[16..19].each_stub_opponents(players[13..19])
        end

        it "pairs fast" do
          Benchmark.realtime { round.pair_numbers }.should be < 0.4
          round.pair_numbers.should eq [[1, 4], [2, 5], [3, 6], [7, 8], [9, 14], [10, 17], [11, 18], [12, 19], [15, 16], [13, 20]]
        end
      end
    end

    context "bracket with an unpairable player" do
      let(:players) { create_players(1..27) }

      context "one of the players can't be paired" do
        before(:each) do
          players[0].stub(opponents: players[1..26])
          players[1..26].each_stub(opponents: [players[0]])
        end

        it "is fast" do
          Benchmark.realtime { round.pair_numbers }.should be < 0.15
          round.pair_numbers.should eq [[2, 15], [3, 16], [4, 17], [5, 18], [6, 19], [7, 20], [8, 21], [9, 22], [10, 23], [11, 24], [12, 25], [13, 26], [14, 27]]
        end
      end
    end

    context "all players in the last bracket had byes" do
      let(:players) { create_players(1..11) }

      before(:each) do
        players[0..7].each_stub(points: 1)
        players[8..10].each_stub(points: 0)
        players[8..10].each_stub(had_bye?: true)
      end

      it "is very fast" do
        Benchmark.realtime { round.pair_numbers }.should be < 0.1
        round.bye.number.should eq 8
        round.pair_numbers.should eq [[1, 4], [2, 5], [3, 6], [7, 9], [10, 11]]
      end

      context "the players in the last bracket can't be paired" do
        before(:each) do
          players[8..10].each_stub_opponents(players[8..10])
        end

        it "is very fast" do
          Benchmark.realtime { round.pair_numbers }.should be < 0.1
          round.bye.number.should eq 8
          round.pair_numbers.should eq [[1, 3], [2, 4], [5, 9], [6, 10], [7, 11]]
        end
      end
    end

    context "the last player in S1 can only play against the first player in S2" do
      let(:players) { create_players(1..20) }

      before(:each) do
        (players[0..19] - players[9..10]).each_stub_opponents([players[9]])
        players[9].stub_opponents(players[0..19] - players[9..10])
      end

      it "pairs fast" do
        Benchmark.realtime { round.pair_numbers }.should be < 0.1
        round.pair_numbers.should eq [[1, 12], [2, 13], [3, 14], [4, 15], [5, 16], [6, 17], [7, 18], [8, 19], [9, 20], [10, 11]]
      end
    end

    context "the last player in S1 can only play against the first player in S1" do
      let(:players) { create_players(1..20) }

      before(:each) do
        players[1..19].each_stub_opponents([players[9]])
        players[9].stub_opponents(players[1..19])
      end

      it "isn't too slow" do
        Benchmark.realtime { round.pair_numbers }.should be < 2
        round.pair_numbers.should eq [[1, 10], [2, 12], [3, 13], [4, 14], [5, 15], [6, 16], [7, 17], [8, 18], [9, 19], [11, 20]]
      end
    end
  end
end
