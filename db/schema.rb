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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160110121943) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cards", force: true do |t|
    t.string   "front"
    t.string   "back"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "set_id"
    t.integer  "cardsetid"
  end

  create_table "cardsets", force: true do |t|
    t.string   "language"
    t.text     "details"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "gid"
  end

  create_table "games", force: true do |t|
    t.text     "details"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status"
    t.integer  "setid"
  end

  create_table "qcards", force: true do |t|
    t.integer  "cardset_id", limit: 8
    t.integer  "term_id",    limit: 8
    t.text     "term"
    t.text     "definition"
    t.text     "image"
    t.integer  "rank"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qcardsets", force: true do |t|
    t.integer  "cardset_id",       limit: 8
    t.text     "url"
    t.text     "title"
    t.integer  "created_date"
    t.integer  "modified_date"
    t.integer  "published_date"
    t.boolean  "has_images"
    t.string   "lang_terms",       limit: 7
    t.string   "lang_definitions", limit: 7
    t.integer  "creator_id",       limit: 8
    t.text     "description"
    t.string   "likes",                      default: [], array: true
    t.integer  "like_count",                 default: 0
    t.integer  "total_diff",                 default: 0
    t.integer  "diff_count",                 default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tags",                       default: [], array: true
  end

  create_table "tag_descriptors", force: true do |t|
    t.string   "tag_id"
    t.string   "tag_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "socket_id"
    t.text     "details"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "contactkey"
  end

end
