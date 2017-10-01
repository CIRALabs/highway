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

ActiveRecord::Schema.define(version: 20170916223243) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["email"], name: "index_admins_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true, using: :btree
  end

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
