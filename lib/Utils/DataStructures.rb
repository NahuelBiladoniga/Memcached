require 'monitor'
require_relative 'CommandParsing'

class Node

  def initialize(data)
    @data = data
    @next_node = nil
    @prev_node = nil
  end

  attr_accessor :data, :next_node,:prev_node

end

class DataValue

  @@cas_unique = 1

  def initialize(key,flag,exp_time,data_length,data)
    @key = key
    @flag = flag
    @exp_time = exp_time
    @data_length = data_length
    @data = data
    @cas = @@cas_unique
    @@cas_unique += 1
  end

  def change_data(data_length,data)
    @data_length = data_length
    @data = data
  end

  def print_with_cas
    return "VALUE #{@key} #{@flag} #{@exp_time} #{@data_length} #{@cas}\r\n#{@data}\r\n"
  end

  def print
    return "VALUE #{@key} #{@flag} #{@exp_time} #{@data_length}\r\n#{@data}\r\n"
  end

  attr_accessor :exp_time
  attr_reader :key,:flag,:cas,:data,:data_length

end

class Cache extend MonitorMixin

  include MonitorMixin

  def initialize
    super()

    @hash_table = Hash.new
    @first_node = nil
    @last_node = nil
  end

  def get_values(cas,keys)
    self.synchronize do

      values = []
      keys.each do |key|
        if @hash_table[key]!=nil
          data = @hash_table[key].data
          values.push(cas ? data.print_with_cas : data.print)
        end
      end
      return values

    end
  end

  def add(type,key,flag,exp_time,data_length,data)
    self.synchronize do
      data = DataValue.new(key,flag,exp_time,data_length,data)

      if @hash_table.has_key? key
        node = @hash_table[key]

        if type.eql? "add"
          result =  "NOT_STORED"
          data = @hash_table[key].data
        else
          result = "STORED"
        end

        update_node(node,data)

      else
        if type.eql? "replace"
          result =  "NOT_STORED"
        else
          node = Node.new(data)
          prepend_node(node)
          @hash_table[key]=node

          result = "STORED"
        end
      end

      return result
    end
  end

  def concat_data(type,key,data_length,data)
    self.synchronize do

      if @hash_table.has_key?(key)
        hash_data = @hash_table[key].data

        new_data_length = data_length+hash_data.data_length
        new_data = (type.eql? "append") ? hash_data.data + data : data + hash_data.data

        hash_data.change_data(new_data_length,new_data)

        result="STORED"
      else
        result = "NOT_STORED"
      end

      return result

    end
  end

  def update_node(node,data)
    node.data = data
    delete_node(node)
    prepend_node(node)
  end

  def delete_node(node)
    if node.next_node == nil && node.prev_node == nil
      @first_node = @last_node = nil
    elsif node.next_node == nil
      @last_node = node.prev_node
      @last_node.next_node = nil
    elsif node.prev_node == nil
      @first_node = node.next_node
      @first_node.prev_node = nil
    else
      node.next_node.prev_node = node.prev_node
      node.prev_node.next_node = node.next_node
    end

    node.next_node =  nil
    node.prev_node = nil
  end

  def prepend_node(node)

    if @first_node == nil && @last_node == nil
      @first_node = @last_node = node
    else
      @last_node.next_node = node
      node.prev_node = @last_node
      node.next_node = nil
      @last_node = node
    end

  end

end
