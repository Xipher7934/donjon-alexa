class ApplicationController < ActionController::API
  #before_action :check_code

  class NotActivated < StandardError
  end

  rescue_from NotActivated, :with => :not_activated

  def monsterlookup
    require 'net/https'
    require 'nokogiri'

    #monster_name = params[:request][:intent][:slots][:monster][:value]
    monster_name = params[:mname]
    monster_name = monster_name.gsub(/\s+/, '+')
    uri = 'https://donjon.bin.sh/5e/monsters/rpc.cgi?name='+monster_name

    url = URI.parse(uri)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port, use_ssl: true) { |http|
      http.request(req)
    }
    retvar = res.body

    monster_text = JSON.parse(retvar, symbolize_names: true)

    page = Nokogiri::HTML(monster_text[:card])

    mons = {
        name: page.css('h2').text,
        descr: page.css('div.description p em').text
    }
    return_text = "The #{mons[:name]} is a #{mons[:descr]}"

    render json: {
        response: {
            outputSpeech: {
                type: 'PlainText',
                text: return_text
            }
        }
    }, status: :ok
  end

  private

  def not_activated
    render json: { response: 'unauthorized' }, status: :unauthorized
  end

  def check_code
    puts params[:context][:System][:application][:applicationId]
    raise NotActivated unless params[:context][:System][:application][:applicationId] == "amzn1.ask.skill.5016ae81-1c6a-4b4b-8b09-e531dced50c5"
  end

end
