# app/controllers/concerns/response.rb
module Response
  def api_response(object, status = :ok, content = nil)
    render json: object, status: status, content_type: content
  end
end
