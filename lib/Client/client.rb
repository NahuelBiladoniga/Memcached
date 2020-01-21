require 'socket'
require 'logger'

class Client

  def initialize(address,port)
    @address = address
    @port = port
  end

  def start_client
    @socket = TCPSocket.new(@address, @port)
    @is_open = true
  rescue Errno::ECONNREFUSED
    @is_open = false
    raise ClientError.new("Could not connect to: #{@address}:#{@port}")
  end

  def close_client
    @socket.close
    @is_open = false
  end

  def get(*keys)
    validate_connection
    send_get_command("get",*keys)
  end

  def gets(*keys)
    validate_connection
    send_get_command("gets",*keys)
  end

  def set(key,flag,exp_time,data_length,data,no_reply = false)
    send_modify_command("set",key,flag,exp_time,data_length,data,no_reply)
  end

  def add(key,flag,exp_time,data_length,data,no_reply = false)
    send_modify_command("add",key,flag,exp_time,data_length,data,no_reply)
  end

  def replace(key,flag,exp_time,data_length,data,no_reply = false)
    send_modify_command("replace",key,flag,exp_time,data_length,data,no_reply)
  end

  def cas(key,flag,exp_time,data_length,data,cas_unique,no_reply = false)
    send_modify_command("cas",key,flag,exp_time,data_length,data,
      no_reply,cas_unique)
  end

  def prepend(key,flag,exp_time,data_length,data,no_reply = false)
    send_modify_command("prepend",key,flag,exp_time,data_length,data,no_reply)
  end

  def append(key,flag,exp_time,data_length,data,no_reply = false)
    send_modify_command("append",key,flag,exp_time,data_length,data,no_reply)
  end

  private

  def is_positive_integer(num)
    Integer(num)
    num.to_i >= 0
  rescue
    false
  end

  def validate_connection
    if !@is_open
      raise ClientError.new("Connection needs to be established first")
    end
  end

  def send_get_command(command,*keys)
    send_command = command + " "
    keys.each do |key|
      send_command << key + " "
    end
    @socket.puts(send_command)

    values = []
    value_input = @socket.gets.chomp
    unless value_input.eql? "END"
      value_input = value_input.split(" ")
      data_input = @socket.gets.chomp

      key = value_input[1]
      flags = value_input[2].to_i
      data_length = value_input[3].to_i
      data = data_input

      if command.eql? "gets"
        cas_unique = value_input[4]
        values.push(Value.new(key,flags,data_length,data,cas_unique))
      else
        values.push(Value.new(key,flags,data_length,data))
      end
      value_input = @socket.gets.chomp
    end
    values
  end

  def validate_parameters(flag,exp_time,data_length,data,no_reply,cas_unique)

    if !is_positive_integer(flag)
      error_message = "flag must be a positive Integer"
    elsif !is_positive_integer(exp_time)
      error_message = "exp_time must be a positive Integer"
    elsif !is_positive_integer(data_length)
      error_message = "data_length must be a positive Integer"
    elsif !(cas_unique.eql? "") && !is_positive_integer(cas_unique)
      error_message = "cas_unique must be a positive Integer"
    elsif data_length != data.length
      error_message = "data_length and data must have the same length"
    elsif (flag.to_i.to_s(2).length > 16)
      error_message = "flag must have less than 16 bits"
    elsif !!no_reply != no_reply
      error_message = "no_reply must be boolean"
    else
      error_message = ""
    end

    if !(error_message.eql? "")
      raise ClientError.new(error_message)
    end

  end

  def send_modify_command(command,key,flag,exp_time,data_length,data,
    no_reply,cas_unique = "")
    validate_connection
    validate_parameters(flag,exp_time,data_length,data,no_reply,cas_unique)

    @socket.puts("#{command} #{key} #{flag} #{exp_time} #{data_length} #{cas_unique} " +
    (no_reply ? "noreply" : ""))
    @socket.puts(data)

    if !no_reply
      @socket.gets
    end

  end

end

class Value
  def initialize(key,flags,data_length,data,*cas_unique)
    @key = key
    @flags = flags
    @data_length = data_length
    @data = data
    @cas_unique = -1
    if cas_unique.length == 1
      @cas_unique = cas_unique[0]
    end
  end

  def to_s
    "VALUE #{@key} #{@flags} #{@data_length} #{@data}"
  end

  attr_reader :key,:flags,:data_length,:data,:cas_unique

end

class ClientError < StandardError
  def initialize(msg);
    super(msg);
  end
end
