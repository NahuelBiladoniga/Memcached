require_relative 'memory'
require_relative 'commands'

class Cache
  include Commands

  def initialize(time_crawler = 30)
    @memory = Memory.new(time_crawler)
  end

  def get_values(cas, keys)

      values = []
      keys.each do |key|
        if @memory.get_data(key)!=nil
          if @memory.expired_key?(key)
            @memory.remove_data(key)
          else
            data = @memory.get_data(key)
            values.push(cas ? data.print_with_cas : data.print)
          end
        end
      end

      values
  end

  def insert(type, key, flag, exp_time, data_length, data, *cas_unique)
      new_data = DataValue.new(key, flag, exp_time, data_length, data)

      case type
      when SET_CMD
        result = set(new_data)
      when ADD_CMD
        result = add(new_data)
      when REPLACE_CMD
        result = replace(new_data)
      when CAS_CMD
        result = cas(new_data, cas_unique[0])
      end

      result
  end

  def concat_data(type, key, data_length, data)
      if @memory.has_key?(key)
        @memory.refresh(key)
        hash_data = @memory.get_data(key)

        new_data_length = data_length.to_i + hash_data.data_length.to_i
        new_data = (type.eql? APPEND_CMD) ? hash_data.data + data : data + hash_data.data

        hash_data.change_data(new_data_length, new_data)

        result = STORED_MSG
      else
        result = NOT_STORED_MSG
      end

      result
  end

  private

  def set(new_data)
    @memory.insert_data(new_data.key, new_data)
    STORED_MSG
  end

  def add(new_data)
    if @memory.has_key?(new_data.key)
      @memory.refresh(new_data.key)
      result = NOT_FOUND_MSG
    else
      @memory.insert_data(new_data.key, new_data)
      result = STORED_MSG
    end

    result
  end

  def replace(new_data)
    if @memory.has_key?(new_data.key)
      @memory.insert_data(new_data.key, new_data)
      result = STORED_MSG
    else
      result = NOT_STORED_MSG
    end

    result
  end

  def cas(new_data, cas_unique)

    if @memory.has_key?(new_data.key)
      old_data = @memory.get_data(new_data.key)

      if old_data.cas.to_i == cas_unique.to_i
        @memory.insert_data(new_data.key, new_data)
        result = STORED_MSG
      else
        @memory.refresh(new_data.key)
        result = EXISTS_MSG
      end

    else
      result = NOT_FOUND_MSG
    end

    result
  end

end
