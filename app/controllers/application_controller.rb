class ApplicationController < ActionController::API
  before_action :check_code

  class NotActivated < StandardError
  end

  rescue_from NotActivated, :with => :not_activated

  def netflixcontrol
    require 'win32ole'
    control = case [:control]
              when 'pause', 'resume'
                '{SPACE}'
              when 'full screen'
                'F'
              when 'go back'
                '{LEFT}'
              when 'go forward'
                '{RIGHT}'
              when 'mute'
                '{M}'
              else
                ''
              end
    wsh = WIN32OLE.new('Wscript.Shell')
    wsh.SendKeys(control)
    render json: {
      response: {
        outputSpeech: {
          type: 'PlainText',
              text: 'Okay'
        }
      }
    }, status: :ok
  end

  def execute
    require 'win32ole'
    status = false
    intent = params[:request][:intent]

    if intent[:name] == 'bootup'
      status = true
      wsh = WIN32OLE.new('Wscript.Shell')
      wsh.SendKeys('^{ESC}')
      sleep(0.5)
      wsh.SendKeys(intent[:slots][:program][:value])
      sleep(0.5)
      wsh.SendKeys('{ENTER}')

    elsif intent[:name] == 'netflix'
      status = true
      show_code = "/search?q=#{params[:show]}" if params[:show]
      system("start chrome netflix.com#{show_code}")

    elsif intent[:name] == 'shutdown'
      status = true
      system('shutdown')

    elsif intent[:name] == 'restart'
      status = true
      system('restart')

    elsif intent[:name] == 'closeprogram'
      status = true
      wsh = WIN32OLE.new('Wscript.Shell')
      wsh.SendKeys('%{F4}')
    end

    render json: {
      response: {
        outputSpeech: {
          type: 'PlainText',
              text: (status ? 'Okay' : 'I didn\'t understand that.')
        }
      },
        shouldEndSession: true
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
