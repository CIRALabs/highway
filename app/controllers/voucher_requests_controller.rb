class VoucherRequestsController < ApplicationController
  before_action :require_admin
  before_action :set_voucher_request, only: [:show, :edit, :update, :destroy]

  # GET /voucher_requests
  # GET /voucher_requests.json
  def index
    @voucher_requests = VoucherRequest.all
  end

  # GET /voucher_requests/1
  # GET /voucher_requests/1.json
  def show
  end

  # GET /voucher_requests/new
  def new
    @voucher_request = VoucherRequest.new
  end

  # GET /voucher_requests/1/edit
  def edit
  end

  # POST /voucher_requests
  # POST /voucher_requests.json
  def create
    @voucher_request = VoucherRequest.new(voucher_request_params)

    respond_to do |format|
      if @voucher_request.save
        format.html { redirect_to @voucher_request, notice: 'Voucher request was successfully created.' }
        format.json { render :show, status: :created, location: @voucher_request }
      else
        format.html { render :new }
        format.json { render json: @voucher_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /voucher_requests/1
  # PATCH/PUT /voucher_requests/1.json
  def update
    respond_to do |format|
      if @voucher_request.update(voucher_request_params)
        format.html { redirect_to @voucher_request, notice: 'Voucher request was successfully updated.' }
        format.json { render :show, status: :ok, location: @voucher_request }
      else
        format.html { render :edit }
        format.json { render json: @voucher_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /voucher_requests/1
  # DELETE /voucher_requests/1.json
  def destroy
    @voucher_request.destroy
    respond_to do |format|
      format.html { redirect_to voucher_requests_url, notice: 'Voucher request was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_voucher_request
      @voucher_request = VoucherRequest.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def voucher_request_params
      params.fetch(:voucher_request, {})
    end
end
