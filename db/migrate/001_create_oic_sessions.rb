class CreateOicSessions < ActiveRecord::Migration
  def self.up
    create_table :oic_sessions do |t|
      t.references :user, foreign_key: true
      t.string :code
      t.string :state
      t.string :nonce
      t.string :session_state
      t.text :id_token
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at
      t.timestamps
    end

    add_index :oic_sessions, :user_id
    add_index :oic_sessions, :access_token
    add_index :oic_sessions, :refresh_token
    add_index :oic_sessions, :id_token, length: 64
  end
  def self.down
    drop_table :oic_sessions
  end
end
