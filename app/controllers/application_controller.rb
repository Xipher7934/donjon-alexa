class ApplicationController < ActionController::API

  def netflix
    system('start chrome netflix.com')
    render json: true, status: :ok
  end

end
