class CreatePostsTable < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string  :title,   null: false, default: nil
      t.text    :content, null: false, default: nil
      
      t.timestamps
    end
  end
end