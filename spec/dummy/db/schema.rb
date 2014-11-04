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

ActiveRecord::Schema.define(version: 20141103192146) do

  create_table "events", force: true do |t|
    t.datetime "event_date_time"
    t.integer  "user_id"
    t.string   "type"
    t.string   "pid"
    t.string   "software"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "summary"
    t.string   "outcome"
    t.text     "detail"
  end

  add_index "events", ["event_date_time"], name: "index_events_on_event_date_time"
  add_index "events", ["outcome"], name: "index_events_on_outcome"
  add_index "events", ["pid"], name: "index_events_on_pid"
  add_index "events", ["type"], name: "index_events_on_type"

  create_table "minted_ids", force: true do |t|
    t.string   "minted_id"
    t.string   "referent"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "minted_ids", ["minted_id"], name: "index_minted_ids_on_minted_id", unique: true
  add_index "minted_ids", ["referent"], name: "index_minted_ids_on_referent"

  create_table "users", force: true do |t|
    t.string "username", default: "", null: false
  end

  create_table "workflow_states", force: true do |t|
    t.string   "pid"
    t.string   "workflow_state"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "workflow_states", ["pid"], name: "index_workflow_states_on_pid", unique: true
  add_index "workflow_states", ["workflow_state"], name: "index_workflow_states_on_workflow_state"

end
