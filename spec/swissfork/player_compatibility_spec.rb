require "spec_helper"
require "swissfork/player_compatibility"
require "swissfork/player"

module Swissfork
  describe PlayerCompatibility do
    describe "#same_strong_preference" do
      let(:s1_player) { double }
      let(:s2_player) { double }
      let(:compatibility) { PlayerCompatibility.new(s1_player, s2_player) }

      context "different colour preference" do
        before do
          compatibility.stub(same_preference?: false)
          s1_player.stub_degree(:strong)
          s2_player.stub_degree(:strong)
        end

        it "returns false" do
          compatibility.same_strong_preference?.should be false
        end
      end

      context "same colour preference" do
        before do
          compatibility.stub(same_preference?: true)
        end

        context "both players have strong preference" do
          before do
            s1_player.stub_degree(:strong)
            s2_player.stub_degree(:strong)
          end

          it "returns true" do
            compatibility.same_strong_preference?.should be true
          end
        end

        context "one player has mild preference" do
          before do
            s1_player.stub_degree(:mild)
            s2_player.stub_degree(:strong)
          end

          it "returns false" do
            compatibility.same_strong_preference?.should be false
          end
        end

        context "one player has absolute preference" do
          before do
            s1_player.stub_degree(:absolute)
            s2_player.stub_degree(:strong)
          end

          it "returns true" do
            compatibility.same_strong_preference?.should be true
          end
        end
      end
    end
  end
end
