require "swissfork/scoregroup"
require "swissfork/bracket"
require "swissfork/player"

module Swissfork
  describe Scoregroup do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    def create_bracket(numbers, points: 0)
      Bracket.for(create_players(numbers)).tap do |bracket|
        bracket.stub(points: points)
      end
    end

    describe "#pairs" do
      context "heterogeneous bracket" do
        let(:players) { create_players(1..11) }
        let(:bracket) { Bracket.for(players) }

        before(:each) do
          players[0].stub(points: 3.5)
          players[1].stub(points: 3.5)
          players[2..10].each { |player| player.stub(points: 3) }
        end

        context "one of the moved down players can't be paired" do
          before(:each) do
            players[0].stub(opponents: players[1..10])
            players[1..10].each { |player| player.stub(opponents: [players[0]]) }
          end

          context "it's the last bracket" do
            let(:brackets) { [bracket] }
            let(:scoregroup) { Scoregroup.new(bracket, brackets) }

            it "can't pair the bracket" do
              scoregroup.pairs.should be nil
            end
          end

          context "it isn't the last bracket" do
            let(:brackets) do
              [create_bracket(12..20, points: 5), bracket,
               create_bracket(21..30, points: 1),
               create_bracket(31..40, points: 0)]
            end

            let(:scoregroup) { Scoregroup.new(bracket, brackets) }

            it "pairs the bracket and downfloats the moved down player" do
              scoregroup.pair_numbers.should == [[2, 3], [4, 8], [5, 9], [6, 10], [7, 11]]
              scoregroup.leftovers.should == [players[0]]
            end
          end
        end
      end
    end
  end
end
