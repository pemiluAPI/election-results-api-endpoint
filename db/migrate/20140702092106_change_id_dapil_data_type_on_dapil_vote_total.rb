class ChangeIdDapilDataTypeOnDapilVoteTotal < ActiveRecord::Migration
  def change
    change_table :dapil_vote_totals do |t|
      t.change :id_dapil, :string
    end
  end
end
