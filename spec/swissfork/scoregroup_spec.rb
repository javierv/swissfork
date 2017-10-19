require "spec_helper"
require "swissfork/scoregroup"
require "swissfork/player"

module Swissfork
  describe Scoregroup do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
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

    describe "#number_of_required_downfloats" do
      let(:round) { double }

      context "even number of players" do
        let(:players) { create_players(1..8) }

        context "both brackets have an even number of players" do
          let(:scoregroup) { Scoregroup.new(players[0..3], round) }
          let(:last_scoregroup) { Scoregroup.new(players[4..7], round) }

          before(:each) do
            players[0..3].each { |player| player.stub(points: 1) }
            players[4..7].each { |player| player.stub(points: 0) }
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
              players[5..7].each { |player| player.stub_opponents([players[4]]) }
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
            players[0..2].each { |player| player.stub(points: 1) }
            players[3..7].each { |player| player.stub(points: 0) }
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
              players[4..7].each { |player| player.stub_opponents([players[3]]) }
            end

            it "returns one" do
              scoregroup.number_of_required_downfloats.should == 1
            end
          end

          context "three leftovers in the last bracket" do
            before(:each) do
              players[3..5].each { |player| player.stub_opponents(players[3..7]) }
              players[6..7].each { |player| player.stub_opponents(players[3..5]) }
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
            players[0..4].each { |player| player.stub(points: 1) }
            players[5..8].each { |player| player.stub(points: 0) }
            round.stub(scoregroups: [scoregroup, last_scoregroup])
          end

          context "last bracket can be paired" do
            it "returns one" do
              scoregroup.number_of_required_downfloats.should == 1
            end
          end

          context "one player in the last bracket can't be paired" do
            before(:each) do
              players[5].stub_opponents(players[6..8])
              players[6..8].each { |player| player.stub_opponents([players[5]]) }
            end

            # 5 downfloats to play against 6.
            it "returns one" do
              scoregroup.number_of_required_downfloats.should == 1
            end
          end

          context "two players in the last bracket can't be paired" do
            before(:each) do
              players[5..6].each { |player| player.stub_opponents(players[5..8]) }
              players[7..8].each { |player| player.stub_opponents(players[5..6]) }
            end

            # 5 downfloats to play against 6, and 7 gets the bye
            it "returns one" do
              scoregroup.number_of_required_downfloats.should == 1
            end
          end

          context "no players in the last bracket can be paired" do
            before(:each) do
              players[5..8].each { |player| player.stub_opponents(players[5..8]) }
            end

            # 3, 4, and 5 downfloat to play against 6, 7 and 8. 9 gets the bye.
            it "returns three" do
              scoregroup.number_of_required_downfloats.should == 3
            end
          end

          context "all players in the last bracket had byes" do
            before(:each) do
              players[5..8].each { |player| player.stub(had_bye?: true) }
            end

            context "no leftovers in the last bracket" do
              it "returns one" do
                scoregroup.number_of_required_downfloats.should == 1
              end
            end

            context "two leftovers in the last bracket" do
              before(:each) do
                players[5].stub_opponents(players[6..8])
                players[6..8].each { |player| player.stub_opponents([players[5]]) }
              end

              # 1-2, 5 downfloats to receive the bye, 3 and 4 downfloat to complete
              # the pairing against 6.
              it "returns three" do
                scoregroup.number_of_required_downfloats.should == 3
              end
            end
          end
        end

        context "last bracket has and odd number of players" do
          let(:scoregroup) { Scoregroup.new(players[0..3], round) }
          let(:last_scoregroup) { Scoregroup.new(players[4..8], round) }

          before(:each) do
            players[0..3].each { |player| player.stub(points: 1) }
            players[4..8].each { |player| player.stub(points: 0) }
            round.stub(scoregroups: [scoregroup, last_scoregroup])
          end

          context "last bracket can be paired" do
            it "returns zero" do
              scoregroup.number_of_required_downfloats.should == 0
            end
          end

          context "one player in the last bracket can't be paired" do
            before(:each) do
              players[4].stub_opponents(players[5..8])
              players[5..8].each { |player| player.stub_opponents([players[4]]) }
            end

            it "returns zero" do
              scoregroup.number_of_required_downfloats.should == 0
            end
          end

          context "three leftovers in the last bracket" do
            before(:each) do
              players[4..6].each { |player| player.stub_opponents(players[4..8]) }
              players[7..8].each { |player| player.stub_opponents(players[4..6]) }
            end

            it "returns two" do
              scoregroup.number_of_required_downfloats.should == 2
            end
          end

          context "players in the last bracket had byes" do
            before(:each) do
              players[4..8].each { |player| player.stub(had_bye?: true) }
            end

            context "no leftovers in the last bracket" do
              it "returns two" do
                scoregroup.number_of_required_downfloats.should == 2
              end
            end

            context "one leftover in the last bracket" do
              before(:each) do
                players[4].stub_opponents(players[5..8])
                players[5..8].each { |player| player.stub_opponents([players[4]]) }
              end

              it "returns two" do
                scoregroup.number_of_required_downfloats.should == 2
              end
            end

            context "three leftovers in the last bracket" do
              before(:each) do
                players[4..6].each { |player| player.stub_opponents(players[4..8]) }
                players[7..8].each { |player| player.stub_opponents(players[4..6]) }
              end

              it "returns four" do
                scoregroup.number_of_required_downfloats.should == 4
              end
            end
          end

          context "some players in the last bracket had byes" do
            before(:each) do
              players[4..7].each { |player| player.stub(had_bye?: true) }
            end

            context "one leftover who had a bye in the last bracket" do
              before(:each) do
                players[4].stub_opponents(players[5..8])
                players[5..8].each { |player| player.stub_opponents([players[4]]) }
              end

              it "returns two" do
                scoregroup.number_of_required_downfloats.should == 2
              end
            end

            context "three leftovers who had a bye in the last bracket" do
              before(:each) do
                players[4..6].each { |player| player.stub_opponents(players[4..8]) }
                players[7..8].each { |player| player.stub_opponents(players[4..6]) }
              end

              it "returns four" do
                scoregroup.number_of_required_downfloats.should == 4
              end
            end

            context "two players who had a bye have only one possible opponent" do
              before(:each) do
                players[4..5].each { |player| player.stub_opponents(players[4..7]) }
                players[6..7].each { |player| player.stub_opponents(players[4..5]) }
              end

              it "returns two" do
                scoregroup.number_of_required_downfloats.should == 2
              end
            end
          end
        end
      end
    end

    describe "#pairs" do
      let(:round) { double }

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
          players[8..11].each { |player| player.stub_opponents(players[5..11]) }
        end

        it "downfloats some resident players, and some moved down players" do
          scoregroup.pair_numbers.should == [[1, 6], [7, 8]]
          scoregroup.leftover_numbers.should == [2, 3, 4, 5]
        end
      end

      context "downfloats result in worse pairings in the next scoregrouop" do
        let(:players) { create_players(1..12) }
        let(:scoregroup) { Scoregroup.new(players[0..4], round) }
        let(:next_scoregroup) { Scoregroup.new(players[5..7], round) }
        let(:last_scoregroup) { Scoregroup.new(players[8..11], round) }

        before(:each) do
          players[0..4].each { |player| player.stub(points: 2) }
          players[5..7].each { |player| player.stub(points: 1) }
          players[8..11].each { |player| player.stub(points: 0) }
          round.stub(scoregroups: [scoregroup, next_scoregroup, last_scoregroup])
        end

        context "next scoregroup can be paired" do
          before(:each) do
            players[4].stub_opponents(players[5..7])
            players[5..7].each { |player| player.stub_opponents([players[4]]) }
          end

          it "downfloats players allowing the pair" do
            scoregroup.pair_numbers.should == [[1, 3], [2, 5]]
            scoregroup.leftover_numbers.should == [4]
          end
        end

        context "next scoregroup can't be paired" do
          before(:each) do
            players[4..7].each { |player| player.stub_opponents(players[4..7]) }
          end

          it "downfloats players minimizing downfloats in the next scoregroup" do
            scoregroup.pair_numbers.should == [[1, 3], [2, 5]]
            scoregroup.leftover_numbers.should == [4]
          end
        end

        context "next scoregroup can't be paired even with downfloats" do
          before(:each) do
            players[0..4].each { |player| player.stub_opponents(players[5..7]) }
            players[5..7].each { |player| player.stub_opponents(players[0..7]) }
          end

          it "ignores next scoregroup and downfloats the last player" do
            scoregroup.pair_numbers.should == [[1, 3], [2, 4]]
            scoregroup.leftover_numbers.should == [5]
          end
        end

        context "next scoregroup can be paired with MDPs" do
          before(:each) do
            players[0].stub(points: 3)
            players[1..4].each { |player| player.stub_opponents(players[5..7]) }
            players[5..7].each { |player| player.stub_opponents(players[1..7]) }
          end

          it "ignores next scoregroup and downfloats the last player" do
            scoregroup.pair_numbers.should == [[1, 2], [3, 4]]
            scoregroup.leftover_numbers.should == [5]
          end
        end
      end
    end
  end
end
