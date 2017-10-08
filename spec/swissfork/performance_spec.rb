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
            Benchmark.realtime{ round.pair_numbers }.should < 0.03
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
              Benchmark.realtime{ round.pair_numbers }.should < 0.07
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
              Benchmark.realtime{ round.pair_numbers }.should < 0.2
            end
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
              players[12].stub_opponents(players[8..11] + players[13..15])
              players[13].stub_opponents(players[8..12] + players[14..15])
              players[14].stub_opponents(players[8..13] + [players[15]])
              players[15].stub_opponents(players[8..12])
            end

            it "pairs fast" do
              Benchmark.realtime{ round.pair_numbers }.should < 0.2
            end
          end

          context "the last 6 players in the first group can't downfloat" do
            before(:each) do
              players[6..11].each { |player| player.stub_opponents(players[12..15]) }
              players[12].stub_opponents(players[6..11] + players[13..15])
              players[13].stub_opponents(players[6..12] + players[14..15])
              players[14].stub_opponents(players[6..13] + [players[15]])
              players[15].stub_opponents(players[6..12])
            end

            it "pairs at a reasonable speed" do
              Benchmark.realtime{ round.pair_numbers }.should < 1
            end
          end
        end

        context "with 20 players; the last 7 in the first group can't downfloat" do
          let(:players) { create_players(1..20) }

          before(:each) do
            players[0..15].each { |player| player.stub(points: 1) }
            players[16..19].each { |player| player.stub(points: 0) }
            players[9..15].each { |player| player.stub_opponents(players[16..19]) }
            players[16].stub_opponents(players[9..15] + players[17..19])
            players[17].stub_opponents(players[9..16] + players[18..19])
            players[18].stub_opponents(players[9..17] + [players[19]])
            players[19].stub_opponents(players[9..18])
          end

          it "pairs at a decent speed" do
            Benchmark.realtime{ round.pair_numbers }.should < 17
          end
        end
      end
    end
  end
end
