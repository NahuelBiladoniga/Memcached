require 'monitor'

class Cache extend MonitorMixin

  include MonitorMixin

  def initialize(time_crawler = 30)
    super()

    @hash_table = Hash.new
    @first_node = nil
    @last_node = nil

    memory_crawler(time_crawler)

  end

  def get_values(cas,keys)
    self.synchronize do

      values = []
      keys.each do |key|
        if @hash_table[key]!=nil && !expired_key(key)
          data = @hash_table[key].data
          values.push(cas ? data.print_with_cas : data.print)
        end
      end

      return values

    end
  end

  def insert(type,key,flag,exp_time,data_length,data,*cas_unique)
    self.synchronize do

      case type
        when "set"
          result = set(key,flag,exp_time,data_length,data)
        when "add"
          result = add(key,flag,exp_time,data_length,data)
        when "replace"
          result = replace(key,flag,exp_time,data_length,data)
        when "cas"
          result = cas(key,flag,exp_time,data_length,data,cas_unique[0])
      end

      return result
    end
  end

  def concat_data(type,key,data_length,data)
    self.synchronize do

      if @hash_table.has_key?(key)
        hash_data = @hash_table[key].data

        new_data_length = data_length.to_i + hash_data.data_length.to_i
        new_data = (type.eql? "append") ? hash_data.data + data : data + hash_data.data

        hash_data.change_data(new_data_length,new_data)

        result = "STORED"
      else
        result = "NOT_STORED"
      end

      return result

    end
  end

  private

  def set(key,flag,exp_time,data_length,data)
    new_data = DataValue.new(key,flag,exp_time,data_length,data)

    if @hash_table.has_key?(key)
      node = @hash_table[key]
      update_node(node, new_data)
    else
      insert_data(new_data)
    end

    "STORED"
  end

  def add(key,flag,exp_time,data_length,data)
    if @hash_table.has_key?(key)
      node = @hash_table[key]
      put_node_at_start(node)
      result = "NOT_STORED"
    else
      new_data = DataValue.new(key,flag,exp_time,data_length,data)
      insert_data(new_data)
      result = "STORED"
    end

    result
  end

  def replace(key,flag,exp_time,data_length,data)

    if @hash_table.has_key?(key)
      node = @hash_table[key]
      new_data = DataValue.new(key,flag,exp_time,data_length,data)
      update_node(node, new_data)
      result = "STORED"
    else
      result = "NOT_STORED"
    end

    result
  end

  def cas(key,flag,exp_time,data_length,data,cas_unique)

    if @hash_table.has_key?(key)
      node = @hash_table[key]
      old_data = node.data

      if old_data.cas.to_i == cas_unique.to_i
        new_data = DataValue.new(key,flag,exp_time,data_length,data)
        update_node(node, new_data)
        result = "STORED"
      else
        put_node_at_start(node)
        result = "EXISTS"
      end

    else
      result = "NOT_FOUND"
    end

    result
  end

  def remove_data(key)
    delete_node(@hash_table[key])
    @hash_table.delete(key)
  end

  def expired_key(key)
    data = @hash_table[key].data
    exp_time = data.exp_time
    is_expired =  exp_time.to_i != 0 && Time.now.to_i > exp_time

    if is_expired
      remove_data(key)
    end

    is_expired
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

  def insert_data(new_data)
    new_node = Node.new(new_data)
    prepend_node(new_node)
    @hash_table[new_data.key] = new_node
  end

  def update_node(node, new_data)
    put_node_at_start(node)
    node.data = new_data
  end

  def put_node_at_start(node)
    delete_node(node)
    prepend_node(node)
  end

  def memory_crawler(wait_time)
    Thread.new do
      loop do
        sleep(wait_time)
        self.synchronize do

          node_iterator = @last_node

          while node_iterator != nil
            next_node= node_iterator.prev_node

            expired_key(node_iterator.data.key)

            node_iterator = next_node
          end

        end
      end
    end
  end

end

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
    @exp_time = exp_time.to_i == 0 ? 0 :
    (exp_time.to_i > 2592000 ? exp_time.to_i : Time.now.to_i + exp_time.to_i)
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
    return "VALUE #{@key} #{@flag} #{@data_length} #{@cas}\r\n#{@data}\r\n"
  end

  def print
    return "VALUE #{@key} #{@flag} #{@data_length}\r\n#{@data}\r\n"
  end

  attr_accessor :exp_time
  attr_reader :key,:flag,:cas,:data,:data_length

end
