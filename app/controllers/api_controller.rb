class ApiController < ActionController::Metal
  include AbstractController::Rendering
  include ActionController::Renderers::All
  include ActionController::Head
  include ActionController::Redirecting
  include ActionController::DataStreaming
  include Rails.application.routes.url_helpers
  include Response

  private

  def logger
    ActionController::Base.logger
  end

  def log_client_certificate(cert)
    clientname = sprintf("DN: %s", cert.subject.to_s)
    logger.info "Connection from #{clientname}"
  end

  def capture_client_certificate
    clientcert_pem = request.env["SSL_CLIENT_CERT"]
    clientcert_pem ||= request.env["rack.peer_cert"]
    clientcert_pem
  end

end

