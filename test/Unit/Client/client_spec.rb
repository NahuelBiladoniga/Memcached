require "minitest/autorun"
require_relative "../../../lib/Client/client"
require_relative "../../../lib/Server/server"

describe Server do
  before(:all) do
    @server = Server.new("localhost",11211,30)
    Thread.new{
      @server.start_server
     }
     sleep 1
  end

  after do
    @server.close_server
  end

  describe "Client" do
     before(:all) do
       @client = Client.new("localhost",11211)
       @client.start_client
     end

     after do
       @client.close_client
     end

     describe "Set Command" do
       it "Set non exisiting key" do
         @client.set("test1","data",0,24)
         assert_equal "VALUE test1 24 4\ndata\nEND",@client.get("test1").chomp
       end

       it "Set exisiting key" do
         @client.set("test1","testing",0,8)
         @client.set("test1","hb",0,10)
         assert_equal "VALUE test1 10 2\nhb\nEND",@client.get("test1").chomp
       end
     end

     describe "Add Command" do
       it "Add non exisiting key" do
         @client.add("test2n","data",0,24)
         assert_equal "VALUE test2n 24 4\ndata\nEND",@client.get("test2n").chomp
       end

       it "Add exisiting key" do
         @client.set("test2","testing",0,8)
         @client.add("test2","hb",0,10)
         assert_equal "VALUE test2 8 7\ntesting\nEND",@client.get("test2").chomp
       end
     end

     describe "Replace Command" do
       it "Replace non exisiting key" do
         @client.replace("test3n","data",0,24)
         assert_equal "END",@client.get("test3n").chomp
       end

       it "Replace exisiting key" do
         @client.set("test2","testing",0,8)
         @client.replace("test2","hb",0,10)
         assert_equal "VALUE test2 10 2\nhb\nEND",@client.get("test2").chomp
       end
     end

     describe "Prepend Command" do
       it "Prepend non exisiting key" do
         @client.prepend("test4n","data")
         assert_equal "END",@client.get("test4n").chomp
       end

       it "Prepend exisiting key" do
         @client.set("test4","testing",0,8)
         @client.prepend("test4","hb")
         assert_equal "VALUE test4 8 9\nhbtesting\nEND",@client.get("test4").chomp
       end
     end

     describe "Append Command" do
       it "Append non exisiting key" do
         @client.append("test5n","data")
         assert_equal "END",@client.get("test5n").chomp
       end

       it "Append exisiting key" do
         @client.set("test5","testing",0,8)
         @client.append("test5","hb")
         assert_equal "VALUE test5 8 9\ntestinghb\nEND",@client.get("test5").chomp
       end
     end

     describe "Cas command" do
       it "Cas non existing key" do
         @client.cas("test6n","abc",3,0,8)
         assert_equal "END",@client.get("test6n").chomp
       end
       it "Exisiting key with correct cas_unique value" do
         @client.set("test7","testing",0,8)
         cas_unique = @client.gets("test7").chomp.split(" ")[4]
         @client.cas("test7","abc",cas_unique,0,8)
         assert_equal "VALUE test7 8 3\nabc\nEND",@client.get("test7").chomp
       end
       it "Existing key with incorrect cas_unique value" do
         @client.set("test8","testing",0,8)
         cas_unique = @client.gets("test8").chomp.split(" ")[4]
         @client.set("test8","testing",0,8)
         @client.cas("test8","abc",cas_unique,0,8)
         assert_equal "VALUE test8 8 7\ntesting\nEND",@client.get("test8").chomp
       end
     end

   end
end
