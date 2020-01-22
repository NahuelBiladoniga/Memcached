require 'socket'

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
    send_get_command("get",*keys)
  end

  def gets(*keys)
    send_get_command("gets",*keys)
  end

  def set(key,data,exp_time = 0,flag = 0)
    send_modify_command("set",key,data,exp_time,flag)
  end

  def add(key,data,exp_time = 0,flag = 0)
    send_modify_command("add",key,data,exp_time,flag)
  end

  def replace(key,data,exp_time = 0,flag = 0)
    send_modify_command("replace",key,data,exp_time,flag)
  end

  def append(key,data)
    send_modify_command("append",key,data,0,0)
  end

  def prepend(key,data)
    send_modify_command("prepend",key,data,0,0)
  end

  def cas(key,data,cas_unique,exp_time = 0,flag = 0)
    send_modify_command("cas",key,data,exp_time,flag,cas_unique)
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
    validate_connection
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
      cas_unique = (command.eql? "gets")?value_input[4]:nil
      values.push(ClientValue.new(key,flags,data_length,data,cas_unique))

      value_input = @socket.gets.chomp
    end
    values
  end

  def validate_parameters(exp_time,flag,cas_unique)

    if !is_positive_integer(flag)
      error_message = "flag must be a positive Integer"
    elsif !is_positive_integer(exp_time)
      error_message = "exp_time must be a positive Integer"
    elsif !(cas_unique.eql? "") && !is_positive_integer(cas_unique)
      error_message = "cas_unique must be a positive Integer"
    elsif (flag.to_i.to_s(2).length > 16)
      error_message = "flag must have less than 16 bits"
    else
      error_message = ""
    end

    if !(error_message.eql? "")
      raise ClientError.new(error_message)
    end

  end

  def send_modify_command(command,key,data,exp_time,flag,cas_unique = "")
    validate_connection
    validate_parameters(exp_time,flag,cas_unique)

    @socket.puts("#{command} #{key} #{flag} #{exp_time} #{data.length} #{cas_unique}")
    @socket.puts(data)

    @socket.gets
  end

end

class ClientValue
  def initialize(key,flags,data_length,data, cas_unique)
    @key = key
    @flags = flags
    @data_length = data_length
    @data = data
    @cas_unique = cas_unique
  end

  def to_s
    ("VALUE #{@key} #{@flags} #{@data_length} #{@data} #{(cas_unique==nil)?"":cas_unique}").rstrip
  end

  attr_reader :key,:flags,:data_length,:data,:cas_unique

end

class ClientError < StandardError
  def initialize(msg);
    super(msg);
  end
end
