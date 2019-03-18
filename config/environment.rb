# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

$MASAUrl = 'https://highway.sandelman.ca/'
$ADMINTERFACE = false
$TOFU_DEVICE_REGISTER = true

$TGZ_FILE_LOCATION = Rails.root.join("tmp")

$VERSION = "0.9.7"

# gets overritten by config/initializers/revision.rb by capistrano
$REVISION= "devel"

Mime::Type.register "application/voucher-cose+cbor", :vcc
Mime::Type.register "application/pkcs7-mime", :cms
Mime::Type.register "application/cms",        :cms
