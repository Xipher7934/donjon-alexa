class ApplicationController < ActionController::API
  #before_action :check_code

  class NotActivated < StandardError
  end

  rescue_from NotActivated, :with => :not_activated

  def monsterlookup
    require 'net/https'
    require 'nokogiri'

    monster_name = params[:request][:intent][:slots][:monster][:value]
    monster_name = monster_name.gsub(/\s+/, '+')
    uri = 'https://donjon.bin.sh/5e/monsters/rpc.cgi?name='+monster_name

    url = URI.parse(uri)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port, use_ssl: true) { |http|
      http.request(req)
    }
    retvar = res.body

    monster_text = JSON.parse(retvar, symbolize_names: true)

    puts monster_text
    puts monster_text.key?(:card)

    unless monster_text.key?(:card)
      render json: {
        response: {
          outputSpeech: {
            type: 'PlainText',
                text: 'Sorry, I could not find that monster.'
          }
        }
      }, status: :ok
      return
    end
    
    if monster_text[:card].include? 'no description available'
      if monster_text.key?(:matches)
        didyou = (' Did you mean ' + monster_text[:matches].to_sentence(words_connector: ', ', two_words_connector: ' or ', last_word_connector: ', or ') + '?')
      else
        didyou = ''
      end

      render json: {
        response: {
          outputSpeech: {
            type: 'PlainText',
                text: 'Sorry, that monster has no details. ' + didyou
          }
        }
      }, status: :ok
      return
    end

    mons = parse_monster(monster_text[:card])

    if params[:request][:intent][:name] == "monster_lookup"
      return_text = "The #{mons[:name]} is #{mons[:description].with_indefinite_article}. It is CR #{mons[:challenge]}"
    else
      stat = params[:request][:intent][:slots][:stat][:value]
      stat_sym = stat.gsub(' ','').to_sym
      stat_text = mons[stat_sym]
      return_text = "The #{mons[:name]} has #{stat.with_indefinite_article} of #{stat_text}."
    end



    render json: {
      response: {
        outputSpeech: {
          type: 'PlainText',
              text: return_text
        }
      }
    }, status: :ok

  rescue StandardError
    render json: {
      response: {
        outputSpeech: {
          type: 'PlainText',
            text: 'Sorry, something didn\'t work in that request. Try rephrasing your question.'
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

  def parse_monster(html_text)
    page = Nokogiri::HTML(html_text)
    mons = {
      name: page.css('h2').text.strip,
      description: page.css('div.description p em')&.first&.text&.strip || '',
      armorclass: page.at('strong:contains("Armor Class")')&.next&.text&.strip || '',
      hitpoints: page.at('strong:contains("Hit Points")')&.next&.text&.strip || '',
      speed: page.at('strong:contains("Speed")')&.next&.text&.strip || '',
      languages: page.at('strong:contains("Languages")')&.next&.text&.gsub('-','')&.strip || '',
      skills: page.at('strong:contains("Skills")')&.next&.text&.strip || '',
      senses: page.at('strong:contains("Senses")')&.next&.text&.strip || '',
      challengerating: page.at('strong:contains("Challenge")')&.next&.text&.strip || '',
      actions: page.at('h1:contains("Actions")').css('p'),
      strength: page.css('td').collect(&:text)[0],
      dexterity: page.css('td').collect(&:text)[1],
      constitution: page.css('td').collect(&:text)[2],
      intelligence: page.css('td').collect(&:text)[3],
      wisdom: page.css('td').collect(&:text)[4],
      charisma: page.css('td').collect(&:text)[5]
    }
    mons[:description] = mons[:description].split(',').collect(&:strip).reverse.join(', ')
    mons[:hitpoints] = mons[:hitpoints].split(/[\(\)]/).collect(&:strip)
    mons[:hitdice] = mons[:hitpoints][1]
    mons[:hitpoints] = mons[:hitpoints][0]

    puts mons
    mons
  end

end
