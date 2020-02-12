class Node

  def initialize(data)
    @data = data
    @next_node = nil
    @prev_node = nil
  end

  attr_accessor :data, :next_node, :prev_node

end

class DataValue

  MAX_TIME_IN_SEC = 2592000

  @@cas_unique = 1

  def initialize(key, flag, exp_time, data_length, data)
    @key = key
    @flag = flag
    @exp_time = exp_time.to_i == 0 ? 0 :
    (exp_time.to_i > MAX_TIME_IN_SEC ? exp_time.to_i : Time.now.to_i + exp_time.to_i)
    @data_length = data_length
    @data = data
    @cas = @@cas_unique
    @@cas_unique += 1
  end

  def change_data(data_length, data)
    @data_length = data_length
    @data = data
  end

  def print_with_cas
    "VALUE #{@key} #{@flag} #{@data_length} #{@cas}\r\n#{@data}\r\n"
  end

  def print
    "VALUE #{@key} #{@flag} #{@data_length}\r\n#{@data}\r\n"
  end

  attr_accessor :exp_time
  attr_reader :key, :flag, :cas, :data, :data_length

end
