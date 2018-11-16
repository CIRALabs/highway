require 'multipart_body'

# use of ActionController::Metal means that JSON parameters are
# not automatically parsed, which reduces cases of processing bad
# JSON when no JSON is acceptable anyway.
class EstController < ApiController

  def requestvoucher

    clientcert = nil
    clientcert_pem   = request.env["SSL_CLIENT_CERT"]
    clientcert_pem ||= request.env["rack.peer_cert"]
    if clientcert_pem
      clientcert = OpenSSL::X509::Certificate.new(Chariwt::Voucher.decode_pem(clientcert_pem))
    end

    @replytype  = request.content_type

    media_types = HTTP::Accept::MediaTypes.parse(request.env['CONTENT_TYPE'])

    if media_types == nil or media_types.length < 1
      head 406,
           text: "unknown voucher-request content-type: #{request.content_type}"
      return
    end
    media_type = media_types.first

    case
    when ((media_type.mime_type  == 'application/pkcs7-mime' and
           media_type.parameters == { 'smime-type' => 'voucher-request'} ) or
          (media_type.mime_type == 'application/voucher-cms+json'))

      binary_pkcs = Base64.decode64(request.body.read)
      @voucherreq = CmsVoucherRequest.from_pkcs7(binary_pkcs)

    when (media_type.mime_type == 'application/voucher-cose+cbor')
      begin
        @voucherreq = CoseVoucherRequest.from_cbor_cose_io(request.body, clientcert)
      rescue VoucherRequest::InvalidVoucherRequest
        DeviceNotifierMailer.invalid_voucher_request(request).deliver
        head 406,
             text: "voucher request was not signed with known public key"
        return
      end
    else
      head 406,
           text: "unknown voucher-request content-type: #{request.content_type}"
      return
    end

    unless @voucherreq
      head 404, text: 'missing voucher request'
      return
    end

    if clientcert_pem
      @voucherreq.tls_clientcert = clientcert_pem
    end

    # keep the raw encoded request.
    @voucherreq.originating_ip = request.ip

    @voucherreq.save!
    @voucher,@reason = @voucherreq.issue_voucher

    @answered = false
    if @reason == :ok and @voucher

      accept_types = HTTP::Accept::MediaTypes.parse(request.env['HTTP_ACCEPT'])
      accept_types.each { |type|

        case
        when type.mime_type == 'multipart/mixed'
          part1 = Part.new(:body => @voucher.as_issued,    :content_type => 'application/voucher-cose+cbor')
          part2 = Part.new(:body => @voucher.signing_cert.to_pem, :content_type => 'application/pkcs7-mime; smime-type=certs-only')
          @multipart = MultipartBody.new([part1, part2])
          raw_response(@multipart.to_s, :ok, "multipart/mixed; boundary=#{@multipart.boundary}")
          @answered = true

        when ((type.mime_type == 'application/pkcs7-mime' and
               type.parameters == { 'smime-type' => 'voucher'}) or
              (type.mime_type == 'application/pkcs7-mime' and
               type.parameters == { } )                         or
              (type.mime_type == 'application/voucher-cms+json'))
          api_response(@voucher.as_issued, :ok, @replytype)
          @answered = true

        when (type.mime_type == 'application/voucher-cose+cbor')
          raw_response(@voucher.as_issued, :ok, @replytype)
          @answered = true

        when (type.mime_type == '*/*')
          # just ignore this entry, it does not help
          true

        else
          logger.debug "accept type: #{type} not recognized"
          # nothing, inside loop
        end

        break if @answered
      }

      unless @answered
        head 406, text: "no acceptable HTTP_ACCEPT type found"
      end

    else
      logger.error "no voucher issued for #{request.ip}, reason: #{@reason.to_s}"
      head 404, text: @reason.to_s
    end
  end

  def requestauditlog
    binary_pkcs = Base64.decode64(request.body.read)
    @voucherreq = CmsVoucherRequest.from_pkcs7(binary_pkcs)
    @device = @voucherreq.device
    @owner  = @voucherreq.owner

    if @device.device_owned_by?(@owner)
      api_response(@device.audit_log, :ok,
                    'application/json')
    else
      head 404, text: 'invalid device'
    end
  end

end
