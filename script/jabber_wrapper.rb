require 'rubygems'
require 'xmpp4r'

module JabberWrapper
  
  def in_jabber_context(&block)
    @mainthread = Thread.current
    block.call
    send_initial_presence
    Thread.stop
  end

  def login(login, password)
    @jid    = Jabber::JID.new(login)
    @client = Jabber::Client.new(@jid)
    @client.connect
    @client.auth(password)
  end

  def send_initial_presence
    set_status("#{@listener_name} um #{Time.now.utc}")
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
  
  def handle_messages
    @client.add_message_callback do |m|
      begin
        if m.type != :error
          yield m # send(callback, m) #if defined?(@message_method)
        else
          msg = Jabber::Message.new(m.from, "Fehler!")
        end
      rescue => e
        puts "Error: #{e}"
      end
    end
  end
  
  def set_status(status)
    @client.send(Jabber::Presence.new.set_status(status))
  end
  
end