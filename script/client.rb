#!/usr/bin/env ruby

require 'jabber_wrapper'

class SwoopsListener  
  include JabberWrapper
  
  def initialize(login, password, listener_name = "Ruby JabberBot")
    @listener_name = listener_name
    @friends_sent_to = []
    
    in_jabber_context do
      login(login, password)
      handle_messages { |msg| respond_to_message(msg) }
    end    
  end
  
  def respond_to_message(m)    
    if !@friends_sent_to.include?(m.from)
      send_chat_message(m.from, "Hallo! Ich bin #{@listener_name}. Für Hilfe schreibe 'help'.")
      @friends_sent_to << m.from
    end

    case m.body.downcase
    when 'quit'
      send_chat_message(m.from, "und tschüss")
      logout
    when 'help'
      msg = "commands:
      quit => beendet den quizbot
      help => das hier
      brb => kleine status spielerei"
      send_chat_message(m.from, msg)
    when 'brb'
      set_status("#{@listener_name} um #{Time.now.utc} is now afk")
      sleep(1)
      set_status("#{@listener_name} um #{Time.now.utc} is now back")
    else
      send_chat_message(m.from, "Du hast zuletzt um #{@time || Time.now} einen Nicht-Befehl eingegeben.")
      @time = Time.now
    end
  end
  
end

SwoopsListener.new('api@swoop.mindmatters', 'api')