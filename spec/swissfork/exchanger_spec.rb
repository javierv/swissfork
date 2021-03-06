require "create_players_helper"
require "swissfork/exchanger"

module Swissfork
  describe Exchanger do
    describe "#next_exchange" do
      let(:s1_players) { create_players(1..5) }
      let(:s2_players) { create_players(6..11) }
      let(:exchanger) { Exchanger.new(s1_players, s2_players) }

      context "first exchange" do
        before { exchanger.next_exchange }

        it "exchanges the closest players" do
          exchanger.numbers.should eq [1, 2, 3, 4, 6, 5, 7, 8, 9, 10, 11]
        end
      end

      context "second exchange" do
        before { 2.times { exchanger.next_exchange } }

        it "exchanges the next closest players, choosing the bottom player from S1, and reorders them" do
          exchanger.numbers.should eq [1, 2, 3, 4, 7, 5, 6, 8, 9, 10, 11]
        end

        context "players with non-consecutive numbers" do
          let(:s1_players) { create_players([1, 2, 3]) }
          let(:s2_players) { create_players([4, 28, 29, 30]) }

          it "exchanges according to the in-bracket sequence numbers" do
            exchanger.numbers.should eq [1, 2, 28, 3, 4, 29, 30]
          end
        end
      end

      context "third exchange" do
        before { 3.times { exchanger.next_exchange } }

        it "exchanges the next closest players" do
          exchanger.numbers.should eq [1, 2, 3, 5, 6, 4, 7, 8, 9, 10, 11]
        end
      end

      context "exchanges limit reached" do
        let(:one_player_exchanges) { exchanger.s1.count * exchanger.s2.count }
        before { one_player_exchanges.times { exchanger.next_exchange } }

        context "first exchange" do
          before { exchanger.next_exchange }

          it "exchanges two players" do
            exchanger.numbers.should eq [1, 2, 3, 6, 7, 4, 5, 8, 9, 10, 11]
          end
        end

        context "second exchange" do
          before { 2.times { exchanger.next_exchange } }

          it "exchanges the next closest players, choosing the bottom players from S1" do
            exchanger.numbers.should eq [1, 2, 3, 6, 8, 4, 5, 7, 9, 10, 11]
          end
        end
      end
    end

    describe "#limit_reached?" do
      let(:exchanger) { Exchanger.new(s1_players, s2_players) }

      context "no players in s1" do
        let(:s1_players) { [] }
        let(:s2_players) { create_players(1..5) }

        it "returns true" do
          exchanger.limit_reached?.should be true
        end
      end

      context "no players in s2" do
        let(:s1_players) { create_players(1..5) }
        let(:s2_players) { [] }

        it "returns true" do
          exchanger.limit_reached?.should be true
        end
      end

      context "one player in s1 and one player in s2" do
        let(:s1_players) { create_players(1..1) }
        let(:s2_players) { create_players(2..2) }

        context "no exchanges" do
          it "returns false" do
            exchanger.limit_reached?.should be false
          end
        end

        context "one exchange" do
          before { exchanger.next_exchange }

          it "returns true" do
            exchanger.limit_reached?.should be true
          end
        end
      end

      context "one player in s1 and two players in s2" do
        let(:s1_players) { create_players(1..1) }
        let(:s2_players) { create_players(2..3) }

        context "two exchanges" do
          before { 2.times { exchanger.next_exchange } }

          it "returns true" do
            exchanger.limit_reached?.should be true
          end
        end
      end

      context "two players in s1 and one player in s2" do
        let(:s1_players) { create_players(1..2) }
        let(:s2_players) { create_players(3..3) }

        context "one exchange" do
          before { 1.times { exchanger.next_exchange } }

          it "returns false" do
            exchanger.limit_reached?.should be false
          end
        end

        context "two exchanges" do
          before { 2.times { exchanger.next_exchange } }

          it "returns true" do
            exchanger.limit_reached?.should be true
          end
        end
      end

      context "two players in s1 and two players in s2" do
        let(:s1_players) { create_players(1..2) }
        let(:s2_players) { create_players(3..4) }

        context "all individual exchanges done" do
          before { 4.times { exchanger.next_exchange } }

          # Exchanging 2 players doesn't make sense here because
          # the pairings available would be the same pairings as we
          # would get by exchanging no players at all.
          #
          # In theory, it would make sense if two players were required
          # to downfloat, but in that case, brackets now would set S1
          # to only one player.
          it "returns true" do
            exchanger.limit_reached?.should be true
          end
        end
      end
    end
  end
end
