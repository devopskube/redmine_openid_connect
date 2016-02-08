class CreateOicSessions < ActiveRecord::Migration
  def self.up
    create_table :oic_sessions do |t|
      t.references :user, index: true, foreign_key: true
      t.string :code
      t.string :state
      t.string :nonce
      t.string :session_state
      t.text :id_token
      t.string :access_token, index: true
      t.string :refresh_token, index: true
      t.datetime :expires_at
      t.timestamps
    end

    add_index :oic_sessions, :id_token, length: 64
  end
  def self.down
    drop_table :oic_sessions
  end
end
