class EstController < ApiController

  def requestvoucher
    @voucher = Voucher.new

    @vreq = JSON.parse(request.body.read)
    @servcert   = OpenSSL::X509::Certificate.new request.env["SSL_SERVER_CERT"]
    @clientcert = OpenSSL::X509::Certificate.new request.env["SSL_CLIENT_CERT"]
    File.open("log/n1.log", "w") do |f|
      f.puts @clientcert.public_key
      f.puts "body2:"
      f.puts @vreq.to_s
    end
    json_response(@voucher, :ok)
  end
end
