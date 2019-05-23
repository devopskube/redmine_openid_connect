class CreateOicSessions < ActiveRecord::Migration[4.2]
  def self.up
    create_table :oic_sessions do |t|
      t.references :user, foreign_key: true
      t.text :code
      t.string :state
      t.string :nonce
      t.string :session_state
      t.text :id_token
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at
      t.timestamps
    end

    add_index :oic_sessions, :user_id
    add_index :oic_sessions, :access_token, length: 64
    add_index :oic_sessions, :refresh_token, length: 64
    add_index :oic_sessions, :id_token, length: 64
  end
  def self.down
    drop_table :oic_sessions
  end
end
