require_relative 'commands'
module InputParser
  include Commands
  
  SUCCESS_MSG = "OK"
  ERROR_MSG = "ERROR"
  ERROR_DATA_CHUNK = "CLIENT_ERROR bad data chunk"
  ERROR_LINE_FORMAT = "CLIENT_ERROR bad command line format"


  def is_positive_integer(num)
    Integer(num)
    num.to_i >= 0
  rescue
    false
  end

  def is_retrival_cmd(cmd)
    RETRIVAL_CMDS.include? (cmd.split(" ")[0])
  end

  def validate_data(cmd, data)
    (cmd.split(" ")[4].to_i == data.length.to_i) ? SUCCESS_MSG : ERROR_DATA_CHUNK
  end

  def validate_command(command)
    cmd_splited = command.split(" ")

    command = cmd_splited[0]

    if RETRIVAL_CMDS.include? command
      result = SUCCESS_MSG
    elsif STORAGE_CMDS.include? command

      if cmd_splited.length < 5 ||
        cmd_splited.length > ((command.eql? CAS_CMD) ? 7 : 6)
        result = ERROR_MSG
      else
        result = SUCCESS_MSG

        flags = cmd_splited[2]
        exptime = cmd_splited[3]
        bytes = cmd_splited[4]

        if (flags.to_i.to_s(2).length > 16) || !is_positive_integer(flags) ||
          !is_positive_integer(exptime) || !is_positive_integer(bytes)
          result = ERROR_LINE_FORMAT
        end

      end
    else
      result = ERROR_MSG
    end

    result
  end
end
