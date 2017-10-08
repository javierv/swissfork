require "spec_helper"
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

    describe "#impossible_to_pair?" do
      let(:round) { double }
      let(:players) { create_players(1..12) }

      context "one pairable scoregroup" do
        let(:scoregroup) { Scoregroup.new(players, round) }
        before(:each) { round.stub(scoregroups: [scoregroup])  }

        it "returns false" do
          scoregroup.impossible_to_pair?.should be false
        end
      end

      context "two scoregroup, last one is unpairable" do
        let(:penultimate_scoregroup) { Scoregroup.new(players[0..5], round) }
        let(:last_scoregroup) { Scoregroup.new(players[6..11], round) }

        before(:each) do
          players[0..5].each { |player| player.stub(points: 1) }
          players[6..11].each { |player| player.stub(points: 0) }
          round.stub(scoregroups: [penultimate_scoregroup, last_scoregroup])
          players[11].stub_opponents(players[6..10])
          players[6..10].each { |player| player.stub_opponents([players[11]]) }
        end

        it "the last one returns true" do
          last_scoregroup.impossible_to_pair?.should be true
        end

        it "the penultimate one returns true" do
          penultimate_scoregroup.impossible_to_pair?.should be false
        end
      end

      context "three scoregroups, with one unpairable player" do
        let(:first_scoregroup) { Scoregroup.new(players[0..3], round) }
        let(:penultimate_scoregroup) { Scoregroup.new(players[4..7], round) }
        let(:last_scoregroup) { Scoregroup.new(players[8..11], round) }

        before(:each) do
          players[0..3].each { |player| player.stub(points: 2) }
          players[4..7].each { |player| player.stub(points: 1) }
          players[8..11].each { |player| player.stub(points: 0) }
          round.stub(scoregroups: [first_scoregroup, penultimate_scoregroup, last_scoregroup])
        end

        context "the player can't be paired in the last scoregroup" do
          before(:each) do
            players[11].stub_opponents(players[8..10])
            players[8..10].each { |player| player.stub_opponents([players[11]]) }
          end

          it "returns true only for the last scoregroup" do
            first_scoregroup.impossible_to_pair?.should be false
            penultimate_scoregroup.impossible_to_pair?.should be false
            last_scoregroup.impossible_to_pair?.should be true
          end
        end

        context "the player can't be paired in the last two scoregroups" do
          context "the player is in the last scoregroup" do
            before(:each) do
              players[11].stub_opponents(players[4..10])
              players[4..10].each { |player| player.stub_opponents([players[11]]) }
            end

            it "returns true for the last two scoregroups" do
              first_scoregroup.impossible_to_pair?.should be false
              penultimate_scoregroup.impossible_to_pair?.should be true
              last_scoregroup.impossible_to_pair?.should be true
            end
          end

          context "the player is in the penultimate scoregroup" do
            before(:each) do
              players[7].stub_opponents(players[4..11])
              players[4..6].each { |player| player.stub_opponents([players[7]]) }
              players[8..11].each { |player| player.stub_opponents([players[7]]) }
            end

            it "returns true for the penultimate scoregroup" do
              first_scoregroup.impossible_to_pair?.should be false
              penultimate_scoregroup.impossible_to_pair?.should be true
              last_scoregroup.impossible_to_pair?.should be false
            end
          end
        end

        context "the player can't be paired at all" do
            before(:each) do
              players[11].stub_opponents(players[0..10])
              players[0..10].each { |player| player.stub_opponents([players[11]]) }
            end

            it "returns true for all scoregroups" do
              first_scoregroup.impossible_to_pair?.should be true
              penultimate_scoregroup.impossible_to_pair?.should be true
              last_scoregroup.impossible_to_pair?.should be true
            end
        end
      end
    end

    describe "#number_of_required_downfloats" do
      let(:round) { double }

      context "even number of players" do
        let(:players) { create_players(1..8) }

        context "both brackets have an even number of players" do
          let(:scoregroup) { Scoregroup.new(players[0..3], round) }
          let(:last_scoregroup) { Scoregroup.new(players[4..7], round) }

          before(:each) do
            players[0..3].each { |player| players.stub(points: 1) }
            players[4..7].each { |player| players.stub(points: 0) }
            round.stub(scoregroups: [scoregroup, last_scoregroup])
          end

          context "last bracket can be paired" do
            it "returns zero" do
              scoregroup.number_of_required_downfloats.should == 0
            end
          end

          context "two leftovers in the last bracket" do
            before(:each) do
              players[4].stub_opponents(players[5..7])
              players[5..7].each { |player| players.stub_opponents([players[4]]) }
            end

            it "returns two" do
              scoregroup.number_of_required_downfloats.should == 2
            end
          end
        end

        context "both brackets have an odd number of players" do
          let(:scoregroup) { Scoregroup.new(players[0..2], round) }
          let(:last_scoregroup) { Scoregroup.new(players[3..7], round) }

          before(:each) do
            players[0..2].each { |player| players.stub(points: 1) }
            players[3..7].each { |player| players.stub(points: 0) }
            round.stub(scoregroups: [scoregroup, last_scoregroup])
          end

          context "last bracket can be paired" do
            it "returns one" do
              scoregroup.number_of_required_downfloats.should == 1
            end
          end

          context "one player in the last bracket can't be paired" do
            before(:each) do
              players[3].stub_opponents(players[4..7])
              players[4..7].each { |player| players.stub_opponents([players[3]]) }
            end

            it "returns one" do
              scoregroup.number_of_required_downfloats.should == 1
            end
          end

          context "three leftovers in the last bracket" do
            before(:each) do
              players[3].stub_opponents(players[4..7])
              players[4].stub_opponents([players[3]] + players[5..7])
              players[5].stub_opponents(players[3..4] + players[6..7])
              players[6..7].each { |player| players.stub_opponents(players[3..5]) }
            end

            it "returns three" do
              scoregroup.number_of_required_downfloats.should == 3
            end
          end
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..9) }

        context "last bracket has an even number of players" do
          let(:scoregroup) { Scoregroup.new(players[0..4], round) }
          let(:last_scoregroup) { Scoregroup.new(players[5..8], round) }

          before(:each) do
            players[0..4].each { |player| players.stub(points: 1) }
            players[5..8].each { |player| players.stub(points: 0) }
            round.stub(scoregroups: [scoregroup, last_scoregroup])
          end

          context "last bracket can be paired" do
            it "returns one" do
              scoregroup.number_of_required_downfloats.should == 1
            end
          end

          context "two leftovers in the last bracket" do
            before(:each) do
              players[5].stub_opponents(players[6..8])
              players[6..8].each { |player| players.stub_opponents([players[5]]) }
            end

            it "returns three" do
              scoregroup.number_of_required_downfloats.should == 3
            end
          end
        end

        context "last bracket has and odd number of players" do
          let(:scoregroup) { Scoregroup.new(players[0..3], round) }
          let(:last_scoregroup) { Scoregroup.new(players[4..8], round) }

          before(:each) do
            players[0..3].each { |player| players.stub(points: 1) }
            players[4..8].each { |player| players.stub(points: 0) }
            round.stub(scoregroups: [scoregroup, last_scoregroup])
          end

          context "last bracket can be paired" do
            it "returns zero" do
              scoregroup.number_of_required_downfloats.should == 0
            end
          end

          context "one player in the last bracket can't be paired" do
            before(:each) do
              players[5].stub_opponents(players[5..8])
              players[5..8].each { |player| players.stub_opponents([players[4]]) }
            end

            it "returns zero" do
              scoregroup.number_of_required_downfloats.should == 0
            end
          end

          context "three leftovers in the last bracket" do
            before(:each) do
              players[4].stub_opponents(players[5..8])
              players[5].stub_opponents([players[4]] + players[6..8])
              players[6].stub_opponents(players[4..5] + players[7..8])
              players[7..8].each { |player| players.stub_opponents(players[4..6]) }
            end

            it "returns two" do
              scoregroup.number_of_required_downfloats.should == 2
            end
          end
        end
      end
    end

    describe "#pairs" do
      let(:round) { double }

      context "heterogeneous bracket" do
        let(:players) { create_players(1..10) }
        let(:scoregroup) { Scoregroup.new(players, round) }

        before(:each) do
          players[0].stub(points: 3.5)
          players[1].stub(points: 3.5)
          players[2..9].each { |player| player.stub(points: 3) }
        end

        context "one of the moved down players can't be paired" do
          before(:each) do
            players[0].stub_opponents(players[1..9])
            players[1..9].each { |player| player.stub_opponents([players[0]]) }
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
                         [create_scoregroup(11..20, round, points: 5), scoregroup,
                          create_scoregroup(21..30, round, points: 1),
                          create_scoregroup(31..40, round, points: 0)]
                        )
            end

            it "pairs the bracket and downfloats the moved down player" do
              scoregroup.pair_numbers.should == [[2, 3], [4, 7], [5, 8], [6, 9]]
              scoregroup.leftover_numbers.should == [1, 10]
            end
          end
        end
      end

      context "heterogeneous PPB, unpairable last bracket" do
        let(:players) { create_players(1..12) }
        let(:scoregroup) { Scoregroup.new(players[0..7], round) }
        let(:last_scoregroup) { Scoregroup.new(players[8..11], round) }

        before(:each) do
          round.stub(scoregroups: [scoregroup, last_scoregroup])

          players[0..3].each { |player| player.stub(points: 2) }
          players[4..7].each { |player| player.stub(points: 1) }
          players[8..11].each { |player| player.stub(points: 0) }

          players[5..7].each { |player| player.stub_opponents(players[8..11]) }
          players[8].stub_opponents(players[5..7] + players[9..11])
          players[9].stub_opponents(players[5..7] + [players[8]] + players[10..11])
          players[10].stub_opponents(players[5..7] + players[9..10] + [players[11]])
          players[11].stub_opponents(players[5..7] + players[8..10])
        end

        it "downfloats some resident players, and some moved down players" do
          scoregroup.pair_numbers.should == [[1, 6], [7, 8]]
          scoregroup.leftover_numbers.should == [2, 3, 4, 5]
        end
      end

      context "downfloats result in worse pairings in the next scoregrouop" do
        let(:players) { create_players(1..10) }
        let(:scoregroup) { Scoregroup.new(players[0..4], round) }
        let(:next_scoregroup) { Scoregroup.new(players[5..7], round) }
        let(:last_scoregroup) { Scoregroup.new(players[8..9], round) }

        before(:each) do
          players[0..4].each { |player| player.stub(points: 2) }
          players[5..7].each { |player| player.stub(points: 1) }
          players[8..9].each { |player| player.stub(points: 0) }
          round.stub(scoregroups: [scoregroup, next_scoregroup, last_scoregroup])

          players[4].stub_opponents(players[5..7])
          players[5..7].each { |player| player.stub_opponents([players[4]]) }
        end

        it "downfloats other players" do
          scoregroup.pair_numbers.should == [[1, 3], [2, 5]]
          scoregroup.leftover_numbers.should == [4]
        end
      end
    end
  end
end
