require 'monitor'
require_relative 'data_structures'

class Memory extend MonitorMixin
  include MonitorMixin

  def initialize(time_interval=30)
    super()

    @hash_table = Hash.new
    @first_node = nil
    @last_node = nil
    @time_interval = time_interval

    memory_crawler
  end

  def insert_data(key, data)
    self.synchronize do
      unless @hash_table.has_key?(key)
        new_node = Node.new(data)
        prepend_node(new_node)
        @hash_table[key] = new_node
      else
        node = @hash_table[key]
        update_node(node, data)
      end
    end
  end

  def remove_data(key)
    self.synchronize do
      delete_node(@hash_table[key])
      @hash_table.delete(key)
    end
  end

  def has_key?(key)
    self.synchronize do
      @hash_table.has_key?(key)
    end
  end

  def get_data(key)
    self.synchronize do
      node = @hash_table[key]
      if node!=nil
        node.data
      else
        nil
      end
    end
  end

  def refresh(key)
    self.synchronize do
      node = @hash_table[key]
      put_node_at_start(node)
    end
  end

  def expired_key?(key)
    self.synchronize do
      data = @hash_table[key].data
      exp_time = data.exp_time
      exp_time.to_i != 0 && Time.now.to_i > exp_time
    end
  end

  private

  def update_node(node, new_data)
    node.data = new_data
    put_node_at_start(node)
  end

  def put_node_at_start(node)
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

  def memory_crawler
    Thread.new do
      loop do
        sleep @time_interval
        self.synchronize do

          node_iterator = @last_node

          while node_iterator != nil
            next_node= node_iterator.prev_node
            is_expired = expired_key?(node_iterator.data.key)
            if is_expired
              remove_data(node_iterator.data.key)
            end
            node_iterator = next_node
          end

        end
      end
    end
  end

end
