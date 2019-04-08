# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

$MASAUrl = 'https://highway.sandelman.ca/'
$ADMINTERFACE = false

# SHG-provisioning controls... replace with appropriate yaml file?
$TOFU_DEVICE_REGISTER = true

# set these in environments/
#$INTERNAL_CA_SHG_DEVICE=false
#$LETENCRYPT_CA_SHG_DEVICE=true

$TGZ_FILE_LOCATION = Rails.root.join("tmp")
$TURRIS_ROOT_LOCATION = Rails.root.join("turris_root")

$VERSION = "0.9.11"

# gets overridden by config/initializers/revision.rb by capistrano
$REVISION ||= "devel"

Mime::Type.register "application/voucher-cose+cbor", :vcc
Mime::Type.register "application/pkcs7-mime", :cms
Mime::Type.register "application/cms",        :cms
