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

      context "same colour preference for all players" do
        before(:each) do
          players.each_stub_preference(:white)
        end

        context "with 20 players" do
          let(:players) { create_players(1..20) }

          it "is very fast" do
            Benchmark.realtime{ round.pair_numbers }.should be < 0.1
          end
        end

        context "the preference is strong" do
          before(:each) do
            players.each_stub_degree(:strong)
          end

          context "with 20 players" do
            let(:players) { create_players(1..20) }

            it "is very fast" do
              Benchmark.realtime{ round.pair_numbers }.should be < 0.1
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
            Benchmark.realtime{ round.pair_numbers }.should be < 0.2
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
            Benchmark.realtime{ round.pair_numbers }.should be < 0.1
            round.pair_numbers.should == [[14, 1], [2, 15], [16, 3], [17, 4], [5, 19], [18, 6], [20, 7], [21, 8], [22, 9], [23, 10], [24, 11], [12, 25], [26, 13]]
          end
        end
      end
    end
  end
end

