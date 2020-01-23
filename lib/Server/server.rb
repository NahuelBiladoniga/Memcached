require 'socket'
require_relative '../Utils/input_parser'
require_relative '../Utils/data_structures'

class ServerError < StandardError
  def initialize(msg);
    super(msg);
  end
end

class Server
  include InputParser

  ADD_CMDS = ["set","add","replace","cas"]
  CONCAT_CMD = ["append","prepend"]

  def initialize(address,port,time_crawler,is_cli = false)
    @address = address
    @port = port
    @cache = Cache.new(time_crawler)
    @is_cli = is_cli
  end

  def close_server
    if @socket != nil
      if @is_cli
        puts "Server closed."
      end
      @socket.close
    end
  end

  def start_server
    if @socket == nil
      @socket = TCPServer.open(@address,@port)
      if @is_cli
        puts "Server started."
      end

      loop do
        Thread.new(@socket.accept) do |client|
          run(client)
        end
      end
    end
  rescue IOError,Interrupt
    if @is_cli
      puts "Server closed."
    end
  rescue Errno::EADDRNOTAVAIL
    raise ServerError.new("address to bind server is invalid")
  end

  private
  def run(client)
    loop do
      cmd = client.gets

      if session_was_closed(client,cmd)
        break
      end

      cmd = cmd.chomp
      command_checker = validate_command(cmd)

      if !(command_checker.eql? "OK")
        client.puts command_checker
      else

        if is_retrival_cmd(cmd)
          values = retrival_operation(cmd)

          values.each do |value|
            client.puts value
          end
          client.puts "END"

        else

          data = client.gets

          if session_was_closed(client,data)
            break
          end

          data = data.chomp
          data_checker = validate_data(cmd,data)

          if !(data_checker.eql? "OK")
            client.puts data_checker
          else
            result = storage_operation(cmd,data)
            if !(result.eql? "")
              client.puts result
            end
          end

        end
      end
    end
  rescue Errno::ECONNABORTED
    client.close
  rescue Errno::EPIPE

  rescue Errno::EMFILE
    raise ServerError.new("too many clients")
  end

  def retrival_operation(cmd)
    cmd_splited = cmd.split(" ")
    @cache.get_values((cmd_splited[0].eql? "gets"),cmd_splited[1..cmd_splited.length-1])
  end

  def storage_operation(cmd,data)
    cmd_splited = cmd.split(" ")

    name = cmd_splited[0]
    key = cmd_splited[1]
    flags = cmd_splited[2]
    exp_time = cmd_splited[3]
    data_length = cmd_splited[4]

    if (name.eql? "cas")
      noreply = cmd_splited.length == 7 && (cmd_splited[6].eql? "noreply")
    else
      noreply = cmd_splited.length == 6 && (cmd_splited[5].eql? "noreply")
    end

    if ADD_CMDS.include? name
      result = @cache.insert(name,key,flags,exp_time,data_length,data,
        (name.eql? "cas") ? cmd_splited[5] : nil)
    else
      result = @cache.concat_data(name,key,data_length,data)
    end
    noreply ? "" : result
  end

  def session_was_closed(client,cmd)
    if cmd == nil || (cmd.chomp.eql? "q")
      client.close
      true
    else
      false
    end
  end
end
