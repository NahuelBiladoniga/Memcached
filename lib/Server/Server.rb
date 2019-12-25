require 'socket'
require_relative '../Utils/InputParser'
require_relative '../Utils/DataStructures'

class Server
  include CommandParsing

  ADD_CMDS = ["set","add","replace","cas"]
  CONCAT_CMD = ["append","prepend"]

  def initialize(address,port)
    @socket = TCPServer.open(address, port)
    puts "Server started."

    @cache = Cache.new

    run_server
  end

  private
  def run_server
    loop do
      Thread.new(@socket.accept) do |client|
        puts "open session of: #{client}"
        run(client)
      end
    end
  end

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

          if session_was_closed(client,cmd)
            break
          end

          data = data.chomp
          data_checker = validate_data(cmd,data)

          if !(data_checker.eql? "OK")
            client.puts data_checker
          else
            client.puts storage_operation(cmd,data)
          end

        end
      end
    end
  end

  def retrival_operation(cmd)
    cmd_splited = cmd.split(" ")
    response = @cache.get_values((cmd_splited[0].eql? "gets"),cmd_splited[1..cmd_splited.length-1])
    (cmd_splited[5].eql? "noreply") ? "" : response
  end

  def storage_operation(cmd,data)
    cmd_splited = cmd.split(" ")

    name = cmd_splited[0]
    key = cmd_splited[1]
    flags = cmd_splited[2]
    exp_time = cmd_splited[3]
    data_length = cmd_splited[4]

    if ADD_CMDS.include? name
      @cache.insert(name,key,flags,exp_time,data_length,data,
        (name.eql? "cas") ? cmd_splited[5] : nil)
    else
      @cache.concat_data(name,key,data_length,data)
    end

  end

  def session_was_closed(client,cmd)
    if cmd == nil
      puts "closing session of: #{client}"
      client.close
      true
    else
      false
    end
  end
end

Server.new("127.0.0.1",2000 )
