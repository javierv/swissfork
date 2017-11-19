require "spec_helper"
require "benchmark"
require "swissfork/round"
require "swissfork/player"

module Swissfork
  describe Round do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    let(:round) { Round.new(players) }

    context "same colour preference for all players" do
      before(:each) do
        players.each_stub_preference(:white)
      end

      context "with 20 players" do
        let(:players) { create_players(1..20) }

        it "is very fast" do
          Benchmark.realtime { round.pair_numbers }.should be < 0.1
        end
      end

      context "the preference is strong" do
        before(:each) do
          players.each_stub_degree(:strong)
        end

        context "with 20 players" do
          let(:players) { create_players(1..20) }

          it "is very fast" do
            Benchmark.realtime { round.pair_numbers }.should be < 0.1
          end
        end
      end

      context "some preferences are mild, and have played against each other" do
        context "with 20 players" do
          let(:players) { create_players(1..20) }

          before(:each) do
            players[0..4].each_stub_degree(:mild)
            players[5..19].each_stub_degree(:strong)
            players[0..1].each_stub_opponents(players[2..19])
            players[2..19].each_stub_opponents(players[0..1])
          end

          it "is very fast" do
            Benchmark.realtime { round.pair_numbers }.should be < 0.1
            round.pair_numbers.should == [[1, 2], [12, 3], [13, 4], [14, 5], [6, 15], [7, 16], [8, 17], [9, 18], [10, 19], [11, 20]]
          end
        end
      end
    end

    context "colour preference guaranteed with transpositions" do
      context "with 32 players" do
        let(:players) { create_players(1..32) }

        before(:each) do
          players[0..15].each_stub_preference(:white)
          players[8..9].each_stub_preference(:black)
          players[16..23].each_stub_preference(:white)
          players[24..31].each_stub_preference(:black)
          players[26..28].each_stub_preference(:white)
          players[0..31].each_stub_degree(:mild)
        end

        it "pairs fast" do
          Benchmark.realtime { round.pair_numbers }.should be < 0.2
          round.pair_numbers.should == [[1, 17], [2, 18], [3, 19], [4, 20], [5, 21], [6, 22], [7, 23], [8, 24], [27, 9], [28, 10], [11, 25], [12, 26], [13, 29], [14, 30], [15, 31], [16, 32]]
        end
      end

      context "complex case with 26 players" do
        let(:players) { create_players(1..26) }

        before(:each) do
          players[0].stub_preference(:black)
          players[1].stub_preference(:white)
          players[2..3].each_stub_preference(:black)
          players[4].stub_preference(:white)
          players[5..10].each_stub_preference(:black)
          players[11].stub_preference(:white)
          players[12].stub_preference(:black)

          players[13].stub_preference(:white)
          players[14].stub_preference(:black)
          players[15].stub_preference(nil)
          players[16].stub_preference(:black)
          players[17].stub_preference(:white)
          players[18].stub_preference(:black)
          players[19].stub_preference(:white)
          players[20..21].each_stub_preference(:black)
          players[22..23].each_stub_preference(:white)
          players[24..25].each_stub_preference(:black)

          players[0..31].each_stub_degree(:mild)
        end

        it "pairs fast" do
          Benchmark.realtime { round.pair_numbers }.should be < 0.1
          round.pair_numbers.should == [[14, 1], [2, 15], [16, 3], [17, 4], [5, 19], [18, 6], [20, 7], [21, 8], [22, 9], [23, 10], [24, 11], [12, 25], [26, 13]]
        end
      end
    end

    context "opponent incompatibilities force colour violations" do
      context "with 14 players" do
        let(:players) { create_players(1..14) }

        before(:each) do
          players[0..6].each_stub_preference(:white)
          players[7..13].each_stub_preference(:black)
          players[0].stub_opponents(players[7..13])
          players[7..13].each_stub_opponents([players[0]])
        end

        it "pairs fast" do
          Benchmark.realtime { round.pair_numbers }.should be < 0.1
          round.pair_numbers.should == [
            [1, 7], [2, 9], [3, 10], [4, 11], [5, 12], [6, 13], [14, 8]
          ]
        end

        context "heterogeneous bracket" do
          before(:each) do
            players[0..2].each_stub(points: 2)
            players[3..13].each_stub(points: 1)

            players[2].stub_preference(:black)

            players[0..1].each_stub_opponents(players[0..2] + players[7..13])
            players[2].stub_opponents(players[0..6])
            players[3..6].each_stub_opponents([players[2]])
            players[7..13].each_stub_opponents(players[0..1])
          end

          it "pairs fast" do
            Benchmark.realtime { round.pair_numbers }.should be < 0.1
            round.pair_numbers.should == [
              [1, 4], [2, 5], [8, 3], [6, 11], [7, 12], [13, 9], [14, 10]
            ]
          end
        end
      end
    end

    context "players with no colour preference" do
      context "one player in S1" do
        let(:players) { create_players(1..20) }

        before(:each) do
          players[0].stub_preference(nil)
          players[1..9].each_stub_preference(:white)
          players[10..17].each_stub_preference(:black)
          players[18..19].each_stub_preference(:white)
        end

        it "quickly discards pairs against players with the minoritary preference" do
          Benchmark.realtime { round.pair_numbers }.should be < 0.1
          round.pair_numbers.should == [[19, 1], [2, 11], [3, 12], [4, 13], [5, 14], [6, 15], [7, 16], [8, 17], [9, 18], [10, 20]]
        end
      end

      context "one player in S2" do
        let(:players) { create_players(1..20) }

        before(:each) do
          players[0..7].each_stub_preference(:white)
          players[8..19].each_stub_preference(:black)
          players[10].stub_preference(nil)
        end

        it "quickly discards the first players in S1 against that player" do
          Benchmark.realtime { round.pair_numbers }.should be < 0.1
          round.pair_numbers.should == [[1, 12], [2, 13], [3, 14], [4, 15], [5, 16], [6, 17], [7, 18], [8, 19], [11, 9], [20, 10]]
        end
      end

      context "it's possible to have no colour violations" do
        let(:players) { create_players(1..20) }

        before(:each) do
          players[0..7].each_stub_preference(:white)
          (players[8..9] + players[12..19]).each_stub_preference(:black)
          players[10..11].each_stub_preference(nil)
        end

        it "quickly discards pairs against a player with minoritary preference" do
          Benchmark.realtime { round.pair_numbers }.should be < 0.1
          round.pair_numbers.should == [[1, 13], [2, 14], [3, 15], [4, 16], [5, 17], [6, 18], [7, 19], [8, 20], [11, 9], [12, 10]]
        end
      end

      context "four players in S2; one can be paired against minoritary preference" do
        let(:players) { create_players(1..20) }

        before(:each) do
          players[0..6].each_stub_preference(:white)
          (players[7..9] + players[14..19]).each_stub_preference(:black)
          players[10..13].each_stub_preference(nil)
        end

        it "quickly discards the second pair against a player with minoritary preference" do
          Benchmark.realtime { round.pair_numbers }.should be < 0.1
          round.pair_numbers.should == [[1, 11], [2, 15], [3, 16], [4, 17], [5, 18], [6, 19], [7, 20], [12, 8], [13, 9], [14, 10]]
        end
      end
    end
  end
end
