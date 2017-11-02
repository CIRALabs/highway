class StatusController < ActionController::Base

  def index
    respond_to do |format|
      format.html {
        @stats = [['Devices', Device.count],
                  ['Owners',  Owner.count],
                  ['Vouchers',Voucher.count],
                  ['Requests',VoucherRequest.count],
                 ]
        render layout: 'reload'
      }
      format.json {
        json_response({ 'Devices' => Device.count,
                        'Owners'  => Owner.count,
                        'Vouchers'=> Voucher.count,
                        'Requests'=> VoucherRequest.count},
                      :ok, 'application/json')
      }
    end
  end
end
