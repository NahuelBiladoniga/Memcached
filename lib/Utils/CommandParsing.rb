
module CommandParsing

  RETRIVAL_CMDS = ["get","gets"]
  STORAGE_CMDS = ["set","add","replace","append","prepend"]

  def is_retrival_cmd(cmd)
    return RETRIVAL_CMDS.include? (cmd.split(" ")[0])
  end

  def is_positive_integer(num)
    return num.is_a? Integer && num >= 0
  end

  def validate_data(cmd,data)
    cmd_splited = cmd.split(" ")
    (cmd_splited[4].to_i == data.length.to_i) ? "OK" : "CLIENT_ERROR"
  end

  def validate_command(command)
    cmd_splited = command.split(" ")

    command = cmd_splited[0]
    #Parsing first command
    if RETRIVAL_CMDS.include? command
      result = "OK"
    elsif STORAGE_CMDS.include? command

      #Parsing parameters
      if cmd_splited.length < 4
        result = "ERROR"
      else
        result = "OK"
=begin

        #key = cmd_splited[1]
        flags = cmd_splited[2]
        exptime = cmd_splited[3]
        bytes = cmd_splited[4]

        if (9.to_s(2).length > 16) && !is_positive_integer(flags)
          result = "CLIENT_ERROR"
        elsif !is_positive_integer(exptime)
          result = "CLIENT_ERROR"
        elsif !is_positive_integer(bytes)
          result = "CLIENT_ERROR"
        end

=end

      end

    else
      result = "ERROR"
    end

    return result

  end
end

class RetrivalOperation

  def initialize(parm)
    command_splited = command.split(" ")
    @command_name = command_splited[0]
    @keys = command_splited[1..command_splited.length-1]
  end

  attr_reader :keys,:command_name

end

class OperationCommand
  def initialize(command)
    command_splited = command.split(" ")
    @key = command_splited[0]
    @flags = command_splited[1]
    @exptime = command_splited[2]
    @bytes = command_splited[3]
    #@no_reply =

  end

end
