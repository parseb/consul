class Polls::NvotesController < ApplicationController
  before_action :authenticate_user!, except: :success
  skip_before_action :verify_authenticity_token, only: :success
  skip_authorization_check

  def new
    @poll = Poll.find(params[:poll_id])
  end

  def token
    poll = Poll.find(params[:poll_id])
    nvote = current_user.get_or_create_nvote(poll)
    message = nvote.generate_message
    render plain: "#{Poll::Nvote.generate_hash message}/#{message}", status: :ok
  end

  def success
    authorization_hash = request.headers["Authorization"]
    status = Poll::Nvote.store_voter(authorization_hash) ? 200 : 400
    render plain: '', status: status
  end

end
