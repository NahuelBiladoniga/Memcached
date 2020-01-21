COMMANDS = ["set","add","replace","append","prepend"]
MAX_KEY_LENGTH = 20
MAX_FLAG_LENGTH = 1000
MAX_EXP_TIME_LENGTH = 10000
MAX_DATA_LENGTH = 5000
MAX_ROWS = 10000
MAX_KEY_QUANTITY = 30

def random_string(number)
  charset = Array('A'..'Z') + Array('a'..'z') + Array('0'..'1')
  Array.new(number) { charset.sample }.join
end

#LOADING Storage Operations
storage_file = File.open("storage_data.csv","w")
storage_file.puts("cmd,key,flag,exp_time,data_length,data")
rows_storage = rand 1..MAX_ROWS
keys = Array.new

rows_storage.times do
  cmd = COMMANDS.sample
  key = random_string(rand 1..MAX_KEY_LENGTH)
  keys << key
  flag = rand MAX_FLAG_LENGTH
  exp_time = rand MAX_EXP_TIME_LENGTH
  data = random_string(rand MAX_DATA_LENGTH)
  data_length = data.length

  storage_file.puts("#{cmd},#{key},#{flag},#{exp_time},#{data_length},#{data}")
end

storage_file.close

#LOADING Retrival Operations

retrival_file = File.open("retrival_data.csv","w")
retrival_file.puts("keys")

rows_get = rand 1..MAX_ROWS

rows_get.times do
  keys_used = rand MAX_KEY_QUANTITY
  existing_keys_usage = rand keys.length
  keys_non_existing = keys_used - existing_keys_usage

  keys_to_add = ""

  existing_keys_usage.times do
    keys_to_add << keys[rand keys.length] + " "
  end

  keys_non_existing.times do
    keys_to_add << random_string(rand 1..MAX_KEY_LENGTH) + " "
  end

  retrival_file.puts keys_to_add
end

retrival_file.close
