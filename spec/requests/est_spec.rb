# spec/requests/todos_spec.rb
require 'rails_helper'

RSpec.describe 'BRSKI EST API', type: :request do

  describe "voucher request" do
    it "POST /.well-known/est/requestvoucher" do
      # make an HTTPS request for a new voucher
      # this is section 3.3 of RFCXXXX/draft-ietf-anima-dtbootstrap-anima-keyinfra
      token = File.read("spec/files/parboiled_vr-00-D0-E5-F2-00-02.pkcs")
      post "/.well-known/est/requestvoucher", params: token, headers: {
             'CONTENT_TYPE' => 'application/pkcs7-mime; smime-type=voucher-request',
             'ACCEPT'       => 'application/pkcs7-mime; smime-type=voucher'
           }

      expect(response).to have_http_status(200)
      expect(assigns(:voucherreq).device_identifier).to eq('00-D0-E5-F2-00-02')
      expect(assigns(:voucher).owner).to_not be_nil
    end

    it "POST /.well-known/est/requestvoucher" do
      # make an HTTPS request for a new device which does not belong
      # to the MASA ---> it will produce an email about that.
      pubkey_pem = IO::read(File.join("spec","files","jrc_prime256v1.crt"))
      token = IO::read("spec/files/parboiled_vr-00-D0-E5-02-00-20.pkcs")

      expect {
        post "/.well-known/est/requestvoucher", params: token, headers: {
               'CONTENT_TYPE' => 'application/pkcs7-mime; smime-type=voucher-request',
               'ACCEPT'       => 'application/pkcs7-mime; smime-type=voucher',
               'SSL_CLIENT_CERT'=> pubkey_pem
             }

      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response).to have_http_status(404)
    end

    it "POST a voucher request, with an invalid content_type" do
      token = IO::read("spec/files/parboiled_vr_00-D0-E5-F2-10-03.vch")

      expect {
        post "/.well-known/est/requestvoucher", params: token, headers: {
               'CONTENT_TYPE' => 'text/plain',
               'ACCEPT'       => 'application/voucher-cose+cbor',
             }
      }.to change { ActionMailer::Base.deliveries.count }.by(0)

      expect(response).to have_http_status(406)
    end

    it "POST a constrained voucher request, without a client certificate" do
      token = IO::read("spec/files/parboiled_vr_00-D0-E5-F2-10-03.vch")

      expect {
        post "/.well-known/est/requestvoucher", params: token, headers: {
               'CONTENT_TYPE' => 'application/voucher-cose+cbor',
               'ACCEPT'       => 'application/voucher-cose+cbor'
             }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response).to have_http_status(406)
    end

    it "POST a constrained voucher request and get a constrained voucher" do
      token = IO::read("spec/files/parboiled_vr_00-D0-E5-F2-10-03.vch")
      regfile= File.join("spec","files","jrc_prime256v1.crt")
      pubkey_pem = IO::read(regfile)

      expect {
        post "/.well-known/est/requestvoucher", params: token, headers: {
               'CONTENT_TYPE' => 'application/voucher-cose+cbor',
               'ACCEPT'       => 'application/voucher-cose+cbor',
               'SSL_CLIENT_CERT'=> pubkey_pem
             }
        expect(assigns(:reason)).to be :ok
        expect(response).to have_http_status(200)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      outfilename = File.join("tmp", "voucher_00-D0-E5-F2-10-03.vch")
      File.open(outfilename, "wb") do |f| f.write response.body end
    end

    it "POST a constrained voucher request and get a multipart constrained voucher" do
      token = IO::read("spec/files/parboiled_vr_00-D0-E5-F2-10-03.vch")
      regfile= File.join("spec","files","jrc_prime256v1.crt")
      pubkey_pem = IO::read(regfile)

      expect {
        post "/.well-known/est/requestvoucher", params: token, headers: {
               'CONTENT_TYPE' => 'application/voucher-cose+cbor',
               'ACCEPT'       => 'multipart/mixed',
               'SSL_CLIENT_CERT'=> pubkey_pem
             }
        expect(assigns(:reason)).to be :ok
        expect(response).to have_http_status(200)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      outfilename = File.join("tmp", "voucher_00-D0-E5-F2-10-03.mvch")
      File.open(outfilename, "wb") do |f| f.write response.body end
    end

  end

  describe "audit log request" do
    it "expect f20002 to be empty" do
      # make an HTTPS request for a history of owners for a device.
      # this is section 5.7 of RFCXXXX/draft-ietf-anima-dtbootstrap-anima-keyinfra
      token = IO::read("spec/files/parboiled_vr-00-D0-E5-F2-00-02.pkcs")
      post "/.well-known/est/requestauditlog", params: token, headers: {
             'CONTENT_TYPE' => 'application/pkcs7-mime; smime-type=voucher-request',
             'ACCEPT'       => 'application/pkcs7-mime; smime-type=voucher'
           }

      expect(response).to have_http_status(404)
    end

    it "expect f20003 to have one owner which is not this one" do
      pending "needs an another parboiled voucher request"
      token = IO::read("spec/files/parboiled_vr-00-D0-E5-F2-00-02.pkcs")
      post "/.well-known/est/requestauditlog", params: token, headers: {
             'CONTENT_TYPE' => 'application/pkcs7-mime; smime-type=voucher-request',
             'ACCEPT'       => 'application/pkcs7-mime; smime-type=voucher'
           }

      expect(response).to have_http_status(200)
      jbody = JSON.parse(response.body)
      expect(jbody['version']).to_not be_nil
      expect(jbody['events']).to_not  be_nil
      expect(len(jbody['events'])).to be 0
    end

    it "expect f20002 to have one owner" do
      # make an HTTPS request for a history of owners for a device.
      # this is section 5.7 of RFCXXXX/draft-ietf-anima-dtbootstrap-anima-keyinfra
      token = IO::read("spec/files/parboiled_vr-00-D0-E5-F2-00-02.pkcs")
      post "/.well-known/est/requestvoucher", params: token, headers: {
             'CONTENT_TYPE' => 'application/pkcs7-mime; smime-type=voucher-request',
             'ACCEPT'       => 'application/pkcs7-mime; smime-type=voucher'
           }
      expect(response).to have_http_status(200)

      post "/.well-known/est/requestauditlog", params: token, headers: {
             'CONTENT_TYPE' => 'application/pkcs7-mime; smime-type=voucher-request',
             'ACCEPT'       => 'application/pkcs7-mime; smime-type=voucher'
           }

      expect(response).to have_http_status(200)
      jbody = JSON.parse(response.body)
      expect(jbody['version']).to_not be_nil
      expect(jbody['events']).to_not  be_nil
      expect(jbody['events'].size).to be 2
    end
  end

end
