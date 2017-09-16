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

ActiveRecord::Schema.define(version: 20170915143913) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "devices", force: :cascade do |t|
    t.text     "eui64"
    t.text     "pub_key"
    t.integer  "owner_id"
    t.integer  "model_id"
    t.text     "notes"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.text     "serial_number"
  end

  create_table "owners", force: :cascade do |t|
    t.text     "name"
    t.text     "fqdn"
    t.text     "dn"
    t.text     "certificate"
    t.text     "last_ip"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.text     "pubkey"
  end

  create_table "system_variables", force: :cascade do |t|
    t.string  "variable"
    t.string  "value"
    t.integer "number"
  end

  create_table "voucher_requests", force: :cascade do |t|
    t.json     "details"
    t.integer  "owner_id"
    t.integer  "voucher_id"
    t.integer  "device_id"
    t.text     "originating_ip"
    t.text     "nonce"
    t.text     "device_identifier"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.binary   "raw_request"
  end

  create_table "vouchers", force: :cascade do |t|
    t.text     "issuer"
    t.integer  "device_id"
    t.datetime "expires_on"
    t.integer  "owner_id"
    t.text     "requesting_ip"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.text     "nonce"
    t.text     "as_issued"
  end

end
