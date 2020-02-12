require 'socket'
require_relative 'client_handler'

class Client

  def initialize(address, port)
    @address = address
    @port = port
    @is_open = false
    @socket = nil
  end

  def start_client
    begin
      @socket = TCPSocket.open(@address, @port)
      @is_open = true
    rescue Errno::ECONNREFUSED
      @is_open = false
    end
    raise ClientHandler::InvalidServerAddress unless @is_open
  end

  def close_client
    raise ClientHandler::ClientNotConnected if @socket == nil
    @socket.close
    @is_open = false
  end

  def get(*keys)
    send_get_command("get", *keys)
  end

  def gets(*keys)
    send_get_command("gets", *keys)
  end

  def set(key, data, exp_time = 0, flag = 0)
    send_modify_command("set", key, data, exp_time, flag)
  end

  def add(key, data, exp_time = 0, flag = 0)
    send_modify_command("add", key, data, exp_time, flag)
  end

  def replace(key, data, exp_time = 0, flag = 0)
    send_modify_command("replace", key, data, exp_time, flag)
  end

  def append(key, data)
    send_modify_command("append", key, data, 0, 0)
  end

  def prepend(key, data)
    send_modify_command("prepend", key, data, 0, 0)
  end

  def cas(key, data, cas_unique, exp_time = 0, flag = 0)
    send_modify_command("cas", key, data, exp_time, flag, cas_unique)
  end

  private

  def is_positive_integer(num)
    Integer(num)
    num.to_i >= 0
  rescue
    false
  end

  def validate_connection
    raise ClientHandler::ClientNotConnected unless @is_open
  end

  def send_get_command(command, *keys)
    validate_connection
    send_command = command + " "
    keys.each do |key|
      send_command << key + " "
    end

    @socket.puts(send_command)

    result = ""
    begin
      line = @socket.gets.chomp
      result += "#{line}\n"
    end while !(line.eql?"END")

    result
  end

  def send_modify_command(command, key, data, exp_time, flag, cas_unique = "")
    validate_connection
    validate_parameters(exp_time, flag, cas_unique)

    @socket.puts("#{command} #{key} #{flag} #{exp_time} #{data.length} #{cas_unique}")
    @socket.puts(data)

    @socket.gets.chomp
  end


  def validate_parameters(exp_time, flag, cas_unique)

    if !is_positive_integer(flag)
      error_message = "flag must be a positive Integer"
    elsif !is_positive_integer(exp_time)
      error_message = "exp_time must be a positive Integer"
    elsif !(cas_unique.eql? "") && !(is_positive_integer(cas_unique))
      error_message = "cas_unique must be a positive Integer"
    elsif flag.to_i.to_s(2).length > 16
      error_message = "flag must have less than 16 bits"
    else
      error_message = ""
    end

    raise ClientHandler::InvalidParameters.new(error_message) unless error_message.eql? ""
  end

end
