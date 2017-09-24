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
            players[0..8].each { |player| player.stub(:points).and_return(1) }
            players[4..8].each { |player| player.stub(:floats).and_return([:down]) }
          end

          it "is very fast" do
            Benchmark.realtime{ round.pair_numbers }.should < 0.1
          end
        end
      end

      context "30 players" do
        let(:players) { create_players(1..30) }

        context "no obvious downfloat" do

          before(:each) do
            players[0..14].each { |player| player.stub(:points).and_return(1) }
            players[7..14].each { |player| player.stub(:floats).and_return([:down]) }
          end

          it "performs lineally" do
            Benchmark.realtime{ round.pair_numbers }.should < 0.5
          end
        end
      end

      context "50 players" do
        let(:players) { create_players(1..50) }

        context "no obvious downfloat" do
          before(:each) do
            players[0..24].each { |player| player.stub(:points).and_return(1) }
            players[12..24].each { |player| player.stub(:floats).and_return([:down]) }
          end

          # TODO: Pending test.
          # Right now, it looks like the number of calls to pair_for player doesn't
          # increase linearly, and that probably cause performance to drop once
          # we reach a certain number of players.
          # it "performs lineally" do
          #   Benchmark.realtime{ round.pair_numbers }.should < 1
          # end
        end
      end
    end
  end
end
