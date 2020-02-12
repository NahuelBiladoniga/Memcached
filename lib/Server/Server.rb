require 'socket'
require_relative 'server_handler'
require_relative '../Utils/input_parser'
require_relative '../Utils/commands'
require_relative '../Utils/cache'

class Server
  include InputParser
  include Commands

  SERVER_STARTED_MSG = "Server started."
  SERVER_ENDED_MSG = "Server closed."

  def initialize(address, port , time_crawler, is_cli = false)
    @address = address
    @port = port
    @cache = Cache.new(time_crawler)
    @is_cli = is_cli
  end

  def close_server
    if @socket != nil
      if @is_cli
        puts SERVER_ENDED_MSG
      end
      @socket.close
    end
  end

  def start_server
    if @socket == nil

      begin
        @socket = TCPServer.open(@address,@port)
        server_started = true
      rescue Errno::EADDRNOTAVAIL
        server_started = false
      end
      raise ServerHandler::AddressInvalid unless server_started

      if @is_cli
        puts SERVER_STARTED_MSG
      end

      loop do

        Thread.new(@socket.accept) do |client|
          run(client)
        end
      end
    end
  rescue IOError,Interrupt
    if @is_cli
      puts SERVER_ENDED_MSG
    end
  end

  private
  def run(client)
    loop do
      cmd = client.gets

      if session_was_closed(client, cmd)
        break
      end

      cmd = cmd.chomp
      command_checker = validate_command(cmd)

      if !(command_checker.eql? SUCCESS_MSG)
        client.puts command_checker
      else

        if is_retrival_cmd(cmd)
          values = retrival_operation(cmd)

          values.each do |value|
            value = value.split("\r\n")
            value.each do |line|
              client.write("#{line}\r\n")
            end
          end
          client.puts END_LINE

        else

          data = client.gets

          if session_was_closed(client, data)
            break
          end

          data = data.chomp
          data_checker = validate_data(cmd, data)

          if !(data_checker.eql? SUCCESS_MSG)
            client.puts data_checker
          else
            result = storage_operation(cmd, data)
            if !(result.eql? "")
              client.puts result
            end
          end

        end
      end
    end
  rescue Errno::ECONNABORTED, Errno::EPIPE
    client.close
  end

  def retrival_operation(cmd)
    cmd_splited = cmd.split(" ")
    @cache.get_values((cmd_splited[0].eql? GETS_CMD), cmd_splited[1..cmd_splited.length-1])
  end

  def storage_operation(cmd, data)
    cmd_splited = cmd.split(" ")

    name = cmd_splited[0]
    key = cmd_splited[1]
    flags = cmd_splited[2]
    exp_time = cmd_splited[3]
    data_length = cmd_splited[4]

    if (name.eql? CAS_CMD)
      noreply = cmd_splited.length == 7 && (cmd_splited[6].eql? NO_REPLY_MSG)
    else
      noreply = cmd_splited.length == 6 && (cmd_splited[5].eql? NO_REPLY_MSG)
    end

    if ADD_CMDS.include? name
      result = @cache.insert(name, key, flags, exp_time, data_length, data,
        (name.eql? CAS_CMD) ? cmd_splited[5] : nil)
    else
      result = @cache.concat_data(name, key, data_length, data)
    end
    noreply ? "" : result
  end

  def session_was_closed(client, cmd)
    if cmd == nil || (cmd.chomp.eql? END_CLIENT)
      client.close
      true
    else
      false
    end
  end
end
