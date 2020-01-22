# MemCached

MemCached server and client based on the [Memcached Protocol](https://github.com/memcached/memcached/blob/master/doc/protocol.txt). It supports a subset of commands

Retrieval commands:
* get
* gets

Storage commands:
* set
* add
* replace
* append
* prepend
* cas

## Getting Started

These instructions will get you a server and a client running on your local machine.

### Prerequisites

You need Ruby v2.5 or greater. Other versions may work, but are not guaranteed. Clone this repository on the desired path.

### Server

#### Setup CLI

In the path lib/Server:
``` bash
ruby server_cli.rb
```

And the server will start with the following default parameters:

* address: localhost
* port: 11211
* time_crawler: 30

For more details:
``` bash
ruby server_cli.rb -h
```

#### Setup Library

In Ruby, require the library and instantiate a Memcached Server object:
``` ruby
require_relative 'server.rb'

server = Server.new("localhost",11211,30)
server.start_server
```

### Client

#### Setup

In Ruby, require the library and instantiate a Memcached Client object:
``` ruby
require_relative 'client.rb'

client = Client.new("localhost",11211)
client.start_client
```

#### Sample Commands

Adding the first values into Memcached:
``` ruby
key = "hello"
data = "world"

client.set(key,data)
```

Retrive the value:
``` ruby
client.get("hello")
```
It returns an array of ClientValue objects

You can set with an expiration timeout in seconds or UNIX Time and an unique number:
``` ruby
exp_time = 12
flag = 99

client.set(key,data,exp_time,flag)
```

You can get multiple values at once:
``` ruby
client.set("key1","data1")
client.set("key2","data2")

client.get("key1","key2")
```

## Test

### Unit Test

#### Pre-requisites

You need Ruby v2.5 or greater. Other versions may work, but are not guaranteed.

#### How to run

In the path test/Unit:

``` bash
ruby memcached_spec.rb
```

It will run all tests. To run each test individually:

``` bash
ruby client_spec.rb
ruby data_structures_spec.rb
ruby input_parser_spec.rb
```

### Load Test

#### Pre-requisites
You need Ruby v2.5 or greater and JMeter v5.2.1 or greater. Other versions may work, but are not guaranteed.

#### How to run

First, run the data generator

``` bash
ruby data_generator.rb
```

Then:
``` bash
jmeter -n -t .\test_plan.jmx
```

This will generate a file called `results.jtl`. To convert it to HTML:
``` bash
jmeter -g .\results.jtl -o ./results
```
In the folder `results` it will appear a file called `index.html`

## Contact
Created by [@nahuelbiladoniga](https://github.com/NahuelBiladoniga)
## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
