class CreateDapilVoteTotal < ActiveRecord::Migration
  def change
    create_table :dapil_vote_totals do |t|
      t.string :lembaga
      t.integer :id_dapil
      t.string :nama_dapil
      t.integer :id_partai
      t.string :nama_partai
      t.integer :suara_calon_terpilih
      t.integer :peringkat_suara_calon_terpilih
      t.integer :suara_calon_semua
      t.integer :peringkat_suara_calon_semua
      t.integer :suara_partai
      t.integer :peringkat_suara_partai
      t.integer :jumlah_suara
      t.integer :peringkat_jumlah_suara
    end
  end
end
