require 'multipart_body'

# use of ActionController::Metal means that JSON parameters are
# not automatically parsed, which reduces cases of processing bad
# JSON when no JSON is acceptable anyway.
class SmartpledgeController < ApiController

  def enroll
    clientcert  = nil
    @replytype  = request.content_type
    @clientcert = capture_client_certificate

    # params in application/json will get parsed automatically, no need
    # to do anything.
    # the posted certificate will in most cases be identical
    # to the TLS Client Certificate.
    # note: the lookup is by *PUBLIC KEY*, not certificate.

    if params[:cert]
      @owner = Owner.find_or_create_by_base64_certificate(params[:cert])

      @cert = @owner.sign_with_idevid_ca
      send_data @cert.to_der, :type => 'application/pkcs7'

    else
      capture_bad_request
      logger.error "enrollment failed for #{request.ip}, no certificate provided"
      head 406, text: "missing certificate"
    end
  end

  private

  def capture_client_certificate
    clientcert_pem = request.env["SSL_CLIENT_CERT"]
    clientcert_pem ||= request.env["rack.peer_cert"]
    clientcert_pem
  end

  # not sure how/where to capture bad requests
  def capture_bad_request
    junk = Base64.decode64(request.body.read)
    logger.info "Bad owner enrollment: #{junk}"
    head 406
  end

end
