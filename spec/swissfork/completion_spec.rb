require "create_players_helper"
require "swissfork/completion"

module Swissfork
  describe Completion do
    let(:completion) { Completion.new(players) }

    describe "#bye_can_be_selected?" do
      context "even number of players" do
        let(:players) { create_players(1..6) }

        context "all players had byes" do
          before(:each) do
            players[0..5].each_stub(had_bye?: true)
          end

          it "returns true" do
            completion.bye_can_be_selected?.should be true
          end
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..7) }

        context "not all players had byes" do
          before(:each) do
            players[0..5].each_stub(had_bye?: true)
          end

          context "no pairing incompatibilities" do
            it "returns true" do
              completion.bye_can_be_selected?.should be true
            end
          end

          context "pairing incompatibilities" do
            before(:each) do
              players[0].stub_opponents(players[1..5])
              players[1..5].each_stub_opponents([players[0]])
            end

            it "returns false" do
              completion.bye_can_be_selected?.should be false
            end
          end
        end

        context "all players had byes" do
          before(:each) do
            players[0..6].each_stub(had_bye?: true)
          end

          it "returns true" do
            completion.bye_can_be_selected?.should be false
          end
        end
      end
    end

    describe "#all_players_can_be_paired?" do
      let(:players) { create_players(1..12) }

      context "pairable players" do
        it "returns true" do
          completion.all_players_can_be_paired?.should be true
        end
      end

      context "existing opponents still make the players pairable" do
        before(:each) do
          players[11].stub_opponents(players[6..10])
          players[6..10].each_stub_opponents([players[11]])
        end

        it "returns true" do
          completion.all_players_can_be_paired?.should be true
        end
      end

      context "completely unpairable players" do
        before(:each) do
          players[0..11].each_stub_opponents(players[0..11])
        end

        it "returns false" do
          completion.all_players_can_be_paired?.should be false
        end
      end

      context "one player can't be paired at all" do
        before(:each) do
          players[11].stub_opponents(players[0..10])
          players[0..10].each_stub_opponents([players[11]])
        end

        it "returns false" do
          completion.all_players_can_be_paired?.should be false
        end
      end

      context "two players have the same possible opponent" do
        before(:each) do
          players[10..11].each_stub_opponents(players[1..11])
          players[1..9].each_stub_opponents(players[10..11])
        end

        it "returns false" do
          completion.all_players_can_be_paired?.should be false
        end
      end
    end
  end
end
