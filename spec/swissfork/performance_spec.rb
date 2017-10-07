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

      context "18 players" do
        let(:players) { create_players(1..18) }

        context "no obvious downfloat" do
          before(:each) do
            players[0..8].each { |player| player.stub(points: 1) }
            players[4..8].each { |player| player.stub(floats: [:down]) }
          end

          it "is very fast" do
            Benchmark.realtime{ round.pair_numbers }.should < 0.04
          end
        end
      end

      context "30 players" do
        let(:players) { create_players(1..30) }

        context "no obvious downfloat" do

          before(:each) do
            players[0..14].each { |player| player.stub(points: 1) }
            players[7..14].each { |player| player.stub(floats: [:down]) }
          end

          it "performs lineally" do
            Benchmark.realtime{ round.pair_numbers }.should < 0.12
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

          # TODO: improve the time this test takes.
          # Right now, it looks like the number of calls to pair_for player doesn't
          # increase linearly, and that probably cause performance to drop once
          # we reach a certain number of players.
          it "performs lineally" do
            Benchmark.realtime{ round.pair_numbers }.should < 0.5
          end
        end
      end

      context "homogeneous penultimate bracket; the last one can't be paired" do
        let(:players) { create_players(1..16) }

        before(:each) do
          players[0..11].each { |player| player.stub(points: 1) }
          players[12..15].each { |player| player.stub(points: 0) }
          players[8..11].each { |player| player.stub_opponents(players[12..17]) }
          players[12].stub_opponents(players[8..11] + players[13..15])
          players[13].stub_opponents(players[8..12] + players[14..15])
          players[14].stub_opponents(players[8..13] + [players[15]])
          players[15].stub_opponents(players[8..12])
        end

        it "pairs at a reasonable speed" do
          Benchmark.realtime{ round.pair_numbers }.should < 1
        end
      end
    end
  end
end
