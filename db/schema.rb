# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130624041336) do

  create_table "auth_keys", :force => true do |t|
    t.string   "usergroup",  :limit => 20, :null => false
    t.string   "keytype",    :limit => 3,  :null => false
    t.string   "md5",        :limit => 32, :null => false
    t.text     "keydata",                  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "auth_keys", ["md5"], :name => "index_auth_keys_on_md5", :unique => true

  create_table "projects", :force => true do |t|
    t.string   "name",        :limit => 20, :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "projects", ["name"], :name => "index_projects_on_name", :unique => true

  create_table "servers", :force => true do |t|
    t.string   "name",       :null => false
    t.string   "status",     :null => false
    t.integer  "project_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "servers", ["name"], :name => "index_servers_on_name", :unique => true

  create_table "servers_tags", :id => false, :force => true do |t|
    t.integer  "server_id"
    t.integer  "tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "servers_tags", ["server_id"], :name => "index_servers_tags_on_server_id"
  add_index "servers_tags", ["tag_id"], :name => "index_servers_tags_on_tag_id"

  create_table "tag_segments", :force => true do |t|
    t.string   "name",        :limit => 16, :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tag_segments", ["name"], :name => "index_tag_segments_on_name", :unique => true

  create_table "tags", :force => true do |t|
    t.string   "name",           :limit => 20, :null => false
    t.text     "description"
    t.integer  "project_id",                   :null => false
    t.integer  "tag_segment_id",               :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
