#!/usr/bin/env ruby

require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/roster'
require 'yaml'

# Jabber::debug = true

login = 'api@swoop.mindmatters'
password = 'api'

class SwoopsListener
  
  def initialize(login, password, listener_name = "Swoop's QuizBot")
    @listener_name = listener_name
    @friends_sent_to = []
    @aktuelle_frage = ""
    @aktuelle_anwort = ""
    @question_set = false
    
    @questions = YAML.load_file('questions.yml')
    @question_count = @questions.size
    
    
    # puts @questions.inspect
    
    choose_question_set
    
    main do
      login(login, password)

      listen_for_messages

      send_initial_presence
    end
  end
  
  def main(&block)
    @mainthread = Thread.current
    block.call
    Thread.stop
  end
  
  def login(login, password)
    @jid    = Jabber::JID.new(login)
    @client = Jabber::Client.new(@jid)
    @client.connect
    @client.auth(password)
  end
  
  def send_initial_presence
    @client.send(Jabber::Presence.new.set_status("#{@listener_name} um #{Time.now.utc}"))
  end
  
  def logout
    @mainthread.wakeup
    @client.close
  end
  
  def send_chat_message(to, message)
    msg      = Jabber::Message.new(to, message)
    msg.type = :chat
    @client.send(msg)
  end
  
  def listen_for_messages
    @client.add_message_callback do |m|
      begin
        if m.type != :error
          if !@friends_sent_to.include?(m.from)
            # puts "friends"
            send_chat_message(m.from, "Hallo! Ich bin #{@listener_name}. Für Hilfe schreibe 'help'.
            Und hier gleich die erste Frage:")
            post_question(m.from)
            @friends_sent_to << m.from
          end
        
          case m.body.downcase
          when 'shutdown true'
            send_chat_message(m.from, "und tschüss")
            logout
          when 'help'
            msg = "commands:
            shutdown true => beendet den quizbot
            help => das hier
            frage => neue frage
            loesung => loesung auf die frage"
            send_chat_message(m.from, msg)
          when 'frage'
            # TODO: refactoren
            choose_question_set
            send_chat_message(m.from, @aktuelle_frage)
          when 'loesung'
            send_chat_message(m.from, @aktuelle_antwort)
            choose_question_set
          else
            if question_set?
              if m.body =~ /#{@aktuelle_antwort}/i
                send_chat_message(m.from, "Richtig! #{m.from} gewinnt!")
                choose_question_set
                post_question(m.from)
              end
            end
          end
        else
          msg = Jabber::Message.new(m.from, "Fehler!")
        end
      rescue => e
        puts "Error:\n#{e}"
      end
    end
  end
  
  # TODO: objekt draus machen
  def choose_question_set
    index = rand(@question_count) + 1
    @aktuelle_frage = @questions[index]['frage']
    @aktuelle_antwort = @questions[index]['antwort'].to_s.downcase
    @question_set = true
  end
  
  def clear_question_set
    @aktuelle_frage = ""
    @aktuelle_antwort = ""
    @question_set = false
  end
  
  def question_set?
    @question_set == true
  end
  
  def post_question(from)
    send_chat_message(from, @aktuelle_frage)
  end
end

SwoopsListener.new(login, password)