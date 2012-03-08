# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110318094247) do

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.string   "query"
    t.integer  "parent_cid", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ascii_name"
  end

  add_index "categories", ["name"], :name => "index_categories_on_name"

  create_table "contents", :force => true do |t|
    t.integer  "content_type"
    t.text     "json"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "category_id"
  end

  add_index "contents", ["category_id"], :name => "index_contents_on_category_id"

  create_table "pages", :force => true do |t|
    t.string   "url"
    t.boolean  "spam"
    t.string   "title"
    t.string   "original_url"
    t.string   "description"
    t.text     "image_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "alive"
  end

  add_index "pages", ["url"], :name => "index_pages_on_url"

end
