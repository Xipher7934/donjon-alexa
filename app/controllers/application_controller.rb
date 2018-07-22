class ApplicationController < ActionController::API

  def netflix
    show_code = "/search?q=#{params[:show]}" if params[:show]
    system("start chrome netflix.com#{show_code}")
    render json: true, status: :ok
  end

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
    render json: { response: true }, status: :ok
  end

  def bootup
    require 'win32ole'
    wsh = WIN32OLE.new('Wscript.Shell')
    wsh.SendKeys("^{ESC}")
    sleep(0.5)
    wsh.SendKeys(params[:program])
    sleep(0.5)
    wsh.SendKeys("{ENTER}")
    render json: { response: true }, status: :ok
  end

  def closeprogram
    require 'win32ole'
    if params[:program]
      if system('taskkill /f /fi "IMAGENAME eq ' + params[:program] + '*" /im *')
        render json: { response: 'Ok' }, status: :ok
      else
        render json: { response: 'Error' }, status: :unprocessable_entity
      end
    else
      wsh = WIN32OLE.new('Wscript.Shell')
      wsh.SendKeys("%{F4}")
      render json: { response: true }, status: :ok
    end
  end

  def shutdown
    system('shutdown')
  end

  def restart
    system('restart')
  end

end
