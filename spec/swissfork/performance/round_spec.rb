require "spec_helper"
require "benchmark"
require "swissfork/round"
require "swissfork/player"

module Swissfork
  describe Round do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    describe "#pairs" do
      let(:round) { Round.new(players) }

      context "no obvious downfloat" do
        context "18 players" do
          let(:players) { create_players(1..18) }

          before(:each) do
            players[0..8].each { |player| player.stub(points: 1) }
            players[4..8].each { |player| player.stub(floats: [:down]) }
          end

          it "is very fast" do
            Benchmark.realtime{ round.pair_numbers }.should be < 0.03
            round.pair_numbers.should == [[1, 6], [2, 7], [3, 8], [4, 10], [5, 9], [11, 15], [12, 16], [13, 17], [14, 18]]
          end
        end

        context "30 players" do
          let(:players) { create_players(1..30) }

          context "no obvious downfloat" do

            before(:each) do
              players[0..14].each { |player| player.stub(points: 1) }
              players[7..14].each { |player| player.stub(floats: [:down]) }
            end

            it "performs like O(n^2)" do
              Benchmark.realtime{ round.pair_numbers }.should be < 0.07
              round.pair_numbers.should == [[1, 9], [2, 10], [3, 11], [4, 12], [5, 13], [6, 14], [7, 16], [8, 15], [17, 24], [18, 25], [19, 26], [20, 27], [21, 28], [22, 29], [23, 30]]
            end
          end
        end

        context "50 players" do
          let(:players) { create_players(1..50) }

          context "no obvious downfloat" do
            before(:each) do
              players[0..24].each { |player| player.stub(points: 1) }
              players[12..24].each { |player| player.stub(floats: [:down]) }
            end

            it "performs like O(n^2)" do
              Benchmark.realtime{ round.pair_numbers }.should be < 0.2
              round.pair_numbers.should == [
                [1, 14], [2, 15], [3, 16], [4, 17], [5, 18], [6, 19], [7, 20],
                [8, 21], [9, 22], [10, 23], [11, 24], [12, 26], [13, 25],
                [27, 39], [28, 40], [29, 41], [30, 42], [31, 43], [32, 44],
                [33, 45], [34, 46], [35, 47], [36, 48], [37, 49], [38, 50]
              ]
            end
          end
        end
      end

      context "same colour preference for all players" do
        before(:each) do
          players.each { |player| player.stub_preference(:white) }
        end

        context "with 20 players" do
          let(:players) { create_players(1..20) }

          it "pairs fast" do
            Benchmark.realtime{ round.pair_numbers }.should be < 0.1
          end
        end

        context "the preference is strong" do
          before(:each) do
            players.each { |player| player.stub_degree(:strong) }
          end

          context "with 20 players" do
            let(:players) { create_players(1..20) }

            it "pairs fast" do
              Benchmark.realtime{ round.pair_numbers }.should be < 0.1
            end
          end
        end
      end

      context "colour preference guaranteed with transpositions" do
        context "with 16 players" do
          let(:players) { create_players(1..16) }

          before(:each) do
            players[0..1].each { |player| player.stub_preference(:black) }
            players[2..7].each { |player| player.stub_preference(:white) }
            players[8..9].each { |player| player.stub_preference(:black) }
            players[10..12].each { |player| player.stub_preference(:white) }
            players[13..15].each { |player| player.stub_preference(:black) }
          end

          it "pairs at a reasonable speed" do
            Benchmark.realtime{ round.pair_numbers }.should be < 1
            round.pair_numbers.should == [[11, 1], [12, 2], [3, 9], [4, 10], [5, 13], [6, 14], [7, 15], [8, 16]]
          end
        end
      end

      context "downfloats from two rounds ago need to repeat" do
        context "with 15 players" do
          let(:players) { create_players(1..15) }

          before(:each) do
            players[0..13].each { |player| player.stub(floats: [:down]) }
            players[14].stub(floats: [:down, nil])
          end

          it "performs at a reasonable speed" do
            Benchmark.realtime{ round.pair_numbers }.should be < 1
            round.pair_numbers.should == [
              [1, 8], [2, 9], [3, 10], [4, 11], [5, 12], [6, 13], [7, 14]
            ]
          end
        end
      end

      context "homogeneous penultimate bracket; the last one can't be paired" do
        context "16 players, 4 of them in the last group" do
          let(:players) { create_players(1..16) }

          before(:each) do
            players[0..11].each { |player| player.stub(points: 1) }
            players[12..15].each { |player| player.stub(points: 0) }
          end

          context "the last 4 players in the first group can't downfloat" do
            before(:each) do
              players[8..11].each { |player| player.stub_opponents(players[12..15]) }
              players[12..15].each { |player| player.stub_opponents(players[8..15]) }
            end

            it "pairs fast" do
              Benchmark.realtime{ round.pair_numbers }.should be < 0.2
              round.pair_numbers.should == [[1, 9], [2, 10], [3, 11], [4, 12],
                                            [5, 13], [6, 14], [7, 15], [8, 16]]
            end
          end

          context "the last 6 players in the first group can't downfloat" do
            before(:each) do
              players[6..11].each { |player| player.stub_opponents(players[12..15]) }
              players[12..15].each { |player| player.stub_opponents(players[6..15]) }
            end

            it "is very fast" do
              Benchmark.realtime{ round.pair_numbers }.should be < 0.1
              round.pair_numbers.should == [[1, 9], [2, 10], [3, 13], [4, 14], [5, 15], [6, 16], [7, 11], [8, 12]]
            end
          end
        end

        context "with 20 players; the last 7 in the first group can't downfloat" do
          let(:players) { create_players(1..20) }

          before(:each) do
            players[0..15].each { |player| player.stub(points: 1) }
            players[16..19].each { |player| player.stub(points: 0) }
            players[9..15].each { |player| player.stub_opponents(players[16..19]) }
            players[16..19].each { |player| player.stub_opponents(players[9..19]) }
          end

          it "is very fast" do
            Benchmark.realtime{ round.pair_numbers }.should be < 0.1
            round.pair_numbers.should == [[1, 11], [2, 12], [3, 13], [4, 14], [5, 15], [6, 17], [7, 18], [8, 19], [9, 20], [10, 16]]
          end
        end
      end

      context "PPB + last bracket can't be paired" do
        context "20 players, heterogeneous PPB, 4 players in the last bracket" do
          let(:players) { create_players(1..20) }

          before(:each) do
            players[0..5].each { |player| player.stub(points: 3) }
            players[6..11].each { |player| player.stub(points: 2) }
            players[12..15].each { |player| player.stub(points: 1) }
            players[16..19].each { |player| player.stub(points: 0) }
            players[13..15].each { |player| player.stub_opponents(players[16..19]) }
            players[16..19].each { |player| player.stub_opponents(players[13..19]) }
          end

          it "pairs fast" do
            Benchmark.realtime{ round.pair_numbers }.should be < 0.1
            round.pair_numbers.should == [[1, 4], [2, 5], [3, 6], [7, 8], [9, 14], [10, 17], [11, 18], [12, 19], [13, 20], [15, 16]]
          end
        end
      end

      context "all players in the last bracket had byes" do
        let(:players) { create_players(1..11) }

        before(:each) do
          players[0..7].each { |player| player.stub(points: 1) }
          players[8..10].each { |player| player.stub(points: 0) }
          players[8..10].each { |player| player.stub(had_bye?: true) }
        end

        it "pairs fast" do
          Benchmark.realtime{ round.pair_numbers }.should be < 0.05
          round.bye.number.should == 8
          round.pair_numbers.should == [[1, 4], [2, 5], [3, 6], [7, 9], [10, 11]]
        end

        context "the players in the last bracket can't be paired" do
          before(:each) do
            players[8..10].each { |player| player.stub_opponents(players[8..10]) }
          end

          it "pairs fast" do
            Benchmark.realtime{ round.pair_numbers }.should be < 0.05
            round.bye.number.should == 8
            round.pair_numbers.should == [[1, 3], [2, 4], [5, 9], [6, 10], [7, 11]]
          end
        end
      end
    end
  end
end
