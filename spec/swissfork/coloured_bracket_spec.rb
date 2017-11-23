require "spec_helper"
require "swissfork/bracket"
require "swissfork/player"

module Swissfork
  describe Bracket do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    let(:bracket) { Bracket.for(players) }

    describe "#pairs with colours" do
      let(:players) { create_players(1..10) }

      context "homogeneous bracket" do
        before(:each) { players.each_stub(points: 1) }

        context "default exchange is OK" do
          before(:each) do
            players[0..4].each_stub_preference(:white)
            players[5..9].each_stub_preference(:black)
          end

          it "pairs players normally" do
            bracket.pair_numbers.should eq [[1, 6], [2, 7], [3, 8], [4, 9], [5, 10]]
          end
        end

        context "transpositions guarantee colour preferences" do
          before(:each) do
            players[0..3].each_stub_preference(:white)
            players[4].stub_preference(:black)
            players[5..7].each_stub_preference(:black)
            players[8].stub_preference(:white)
            players[9].stub_preference(:black)
          end

          it "pairs maximizing colour preferences" do
            bracket.pair_numbers.should eq [[1, 6], [2, 7], [3, 8], [4, 10], [9, 5]]
          end
        end

        context "several transpositions guarentee colour preference" do
          before(:each) do
            players[0].stub_preference(:white)
            players[2].stub_preference(:white)
            players[4].stub_preference(:white)
            players[5].stub_preference(:white)
            players[7].stub_preference(:white)

            players[1].stub_preference(:black)
            players[3].stub_preference(:black)
            players[6].stub_preference(:black)
            players[8].stub_preference(:black)
            players[9].stub_preference(:black)
          end

          it "transposes players to guarantee colour preference" do
            bracket.pair_numbers.should eq [[1, 7], [6, 2], [3, 9], [8, 4], [5, 10]]
          end
        end

        context "can't guarantee all colour_preferences" do
          before(:each) do
            players[0..3].each_stub_preference(:white)
            players[4..9].each_stub_preference(:black)
          end

          it "makes one player repeat colour" do
            bracket.pair_numbers.should eq [[1, 6], [2, 7], [3, 8], [4, 9], [10, 5]]
          end
        end

        context "one player has no colour preference" do
          before(:each) do
            players[0..3].each_stub_preference(:white)
            players[4..9].each_stub_preference(:black)
            players[5].stub_preference(nil)
          end

          it "pairs that player with someone with minoritary preference" do
            bracket.pair_numbers.should eq [[1, 7], [2, 8], [3, 9], [4, 10], [6, 5]]
          end
        end

        context "several players don't have colour preference" do
          let(:players) { create_players(1..10) }

          before(:each) do
            players[0..2].each_stub_preference(:white)
            players[3..6].each_stub_preference(:black)
            players[7..9].each_stub_preference(nil)
          end

          it "pairs players with any colour preference with the ones with no preference" do
            bracket.pair_numbers.should eq [[1, 6], [2, 7], [3, 8], [9, 4], [10, 5]]
          end
        end

        context "opponent incompatibilities force colour violations" do
          before(:each) do
            players[0..4].each_stub_preference(:white)
            players[5..9].each_stub_preference(:black)

            players[0..3].each_stub_opponents(players[5..9])
            players[5..9].each_stub_opponents(players[0..3])
          end

          it "repeats colours" do
            bracket.pair_numbers.should eq [[1, 3], [2, 4], [5, 8], [9, 6], [10, 7]]
          end

          context "same colour incompatibilities for each colour" do
            before(:each) do
              players[0..3].each_stub_opponents(players[6..9])
              players[6..9].each_stub_opponents(players[0..3])
            end

            it "repeats colours" do
              bracket.pair_numbers.should eq [[1, 4], [2, 5], [3, 6], [9, 7], [10, 8]]
            end
          end
        end
      end

      context "heterogeneous bracket" do
        let(:players) { create_players(1..11) }

        before(:each) do
          players[0..1].each_stub(points: 2)
          players[2..10].each_stub(points: 1)
          players[0..1].each_stub_opponents(players[0..1])

          players[0..10].each_stub_degree(:strong)
        end

        context "descended players have same preference as ascending players" do
          before(:each) do
            players[0..4].each_stub_preference(:white)
            players[5..10].each_stub_preference(:black)
          end

          it "pairs them with lower players" do
            bracket.pair_numbers.should eq [[1, 6], [2, 7], [3, 8], [4, 9], [5, 10]]
          end

          context "they're incompatible with lower players" do
            before(:each) do
              players[0..1].each_stub_opponents(players[0..1] + players[5..10])
              players[5..10].each_stub_opponents(players[0..1])
            end

            it "pairs them with the higher players" do
              bracket.pair_numbers.should eq [[1, 3], [2, 4], [5, 8], [9, 6], [10, 7]]
            end
          end
        end

        context "one descended player has a mild colour preference" do
          before(:each) do
            players[0].stub_preference(:white)
            players[0].stub_degree(:mild)
            players[1..4].each_stub_preference(:black)
            players[5..10].each_stub_preference(:white)
          end

          it "has a lower preference than other players" do
            bracket.pair_numbers.should eq [[6, 1], [7, 2], [8, 3], [9, 4], [10, 5]]
          end
        end
      end

      context "all players have the same colour preference" do
        let(:players) { create_players(1..4) }

        before(:each) do
          players.each_stub(points: 1)
          players.each_stub_preference(:white)
        end

        context "all players have the same preference degree" do
          before(:each) do
            players.each_stub_degree(:strong)
          end

          it "pairs giving priority to the higher players" do
            bracket.pair_numbers.should eq [[1, 3], [2, 4]]
          end
        end

        context "the lower players have a stronger preference" do
          before(:each) do
            players[0..1].each_stub_degree(:strong)
            players[2..3].each_stub_degree(:absolute)
          end

          it "pairs giving priority to the higher players" do
            bracket.pair_numbers.should eq [[3, 1], [4, 2]]
          end
        end

        context "the first players in S1 and S2 have a stronger preference" do
          before(:each) do
            players[0].stub_degree(:strong)
            players[1].stub_degree(:mild)
            players[2].stub_degree(:strong)
            players[3].stub_degree(:mild)
          end

          it "pairs the first player in S1 with the second player in S2" do
            bracket.pair_numbers.should eq [[1, 4], [3, 2]]
          end
        end

        context "some of them have an absolute colour preference" do
          before(:each) do
            players[0].stub_degree(:absolute)
            players[2].stub_degree(:absolute)
            players[1].stub_degree(:mild)
            players[3].stub_degree(:mild)
          end

          context "none of them are topscorers" do
            it "avoids pairing players with same absolute preferences together" do
              bracket.pair_numbers.should eq [[1, 4], [3, 2]]
            end
          end

          context "all of them are topscorers" do
            before(:each) do
              players.each_stub(topscorer?: true)
            end

            it "avoids pairing players with same absolute preferences together" do
              bracket.pair_numbers.should eq [[1, 4], [3, 2]]
            end
          end
        end

        context "all players have an absolute colour preference" do
          before(:each) do
            players.each_stub_degree(:absolute)
          end

          context "none of them are topscorers" do
            it "downfloats all players" do
              bracket.pair_numbers.should eq []
              bracket.leftover_numbers.should eq [1, 2, 3, 4]
            end
          end

          context "all of them are topscorers" do
            before(:each) do
              players.each_stub(topscorer?: true)
            end

            it "pairs those players" do
              bracket.pair_numbers.should eq [[1, 3], [2, 4]]
            end

            context "the first players in S1 and S2 would get -3 colour difference" do
              before(:each) do
                players[0].stub(colour_difference: -2)
                players[1].stub(colour_difference: -1)
                players[2].stub(colour_difference: -2)
                players[3].stub(colour_difference: -1)
              end

              it "avoids pairing them against each other" do
                bracket.pair_numbers.should eq [[1, 4], [3, 2]]
              end
            end
          end

          context "two of them are topscorers" do
            before(:each) do
              players[0].stub(topscorer?: true)
              players[2].stub(topscorer?: true)
            end

            it "avoids pairing non-topscorers" do
              bracket.pair_numbers.should eq [[1, 4], [2, 3]]
            end
          end
        end
      end
    end
  end
end
