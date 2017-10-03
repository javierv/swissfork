require "swissfork/scoregroup"
require "swissfork/player"

module Swissfork
  describe Scoregroup do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    def create_scoregroup(numbers, round, points: 0)
      Scoregroup.new(create_players(numbers), round).tap do |scoregroup|
        scoregroup.stub(points: points)
      end
    end

    describe "#add_player" do
      let(:players) { create_players(1..6) }
      let(:scoregroup) { Scoregroup.new(players, nil) }

      context "player is the lowest player" do
        let(:player) { Player.new(7) }

        it "adds the player to the scoregroup" do
          scoregroup.add_player(player)
          scoregroup.players.should == players + [player]
        end
      end

      context "player isn't the lowest player" do
        let(:player) { Player.new(0) }

        before(:each) { scoregroup.add_player(player) }

        it "sorts the players after adding the player" do
          scoregroup.players.should == [player] + players
        end

        it "redefines S1 and S2" do
          scoregroup.bracket.s1.should == [player] + players[0..1]
          scoregroup.bracket.s2.should == players[2..5]
        end
      end
    end

    describe "#pairs" do
      let(:round) { double }

      context "heterogeneous bracket" do
        let(:players) { create_players(1..11) }
        let(:scoregroup) { Scoregroup.new(players, round) }

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
            before(:each) do
              round.stub(scoregroups: [scoregroup])
            end

            it "can't pair the bracket" do
              scoregroup.pairs.should be nil
            end
          end

          context "it isn't the last bracket" do
            before(:each) do
              round.stub(scoregroups:
                         [create_scoregroup(12..20, round, points: 5), scoregroup,
                          create_scoregroup(21..30, round, points: 1),
                          create_scoregroup(31..40, round, points: 0)]
                        )
            end

            it "pairs the bracket and downfloats the moved down player" do
              scoregroup.pair_numbers.should == [[2, 3], [4, 8], [5, 9], [6, 10], [7, 11]]
              scoregroup.leftover_numbers.should == [1]
            end
          end
        end
      end
    end
  end
end
