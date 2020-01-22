require "minitest/autorun"
require_relative "../../../lib/Client/client"
require_relative "../../../lib/Server/server"

describe Server do
  before(:all) do
    @server = Server.new("localhost",2000,30)
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
       @client = Client.new("localhost",2000)
       @client.start_client
     end

     after do
       @client.close_client
     end

     describe "Set Command" do
       it "Set non exisiting key" do
         @client.set("test1","data",0,24)
         assert_equal "VALUE test1 24 4 data",@client.get("test1")[0].to_s.chomp
       end

       it "Set exisiting key" do
         @client.set("test1","testing",0,8)
         @client.set("test1","hb",0,10)
         assert_equal "VALUE test1 10 2 hb",@client.get("test1")[0].to_s.chomp
       end
     end

     describe "Add Command" do
       it "Add non exisiting key" do
         @client.add("test2","data",0,24)
         assert_equal "VALUE test2 24 4 data",@client.get("test2")[0].to_s.chomp
       end

       it "Add exisiting key" do
         @client.set("test2","testing",0,8)
         @client.add("test2","hb",0,10)
         assert_equal "VALUE test2 8 7 testing",@client.get("test2")[0].to_s.chomp
       end
     end

     describe "Replace Command" do
       it "Replace non exisiting key" do
         @client.replace("test3","data",0,24)
         assert_equal "",@client.get("test3")[0].to_s.chomp
       end

       it "Replace exisiting key" do
         @client.set("test2","testing",0,8)
         @client.replace("test2","hb",0,10)
         assert_equal "VALUE test2 10 2 hb",@client.get("test2")[0].to_s.chomp
       end
     end

     describe "Prepend Command" do
       it "Prepend non exisiting key" do
         @client.prepend("test4","data")
         assert_equal "",@client.get("test4")[0].to_s.chomp
       end

       it "Prepend exisiting key" do
         @client.set("test4","testing",0,8)
         @client.prepend("test4","hb")
         assert_equal "VALUE test4 8 9 hbtesting",@client.get("test4")[0].to_s.chomp
       end
     end

     describe "Append Command" do
       it "Append non exisiting key" do
         @client.append("test5","data")
         assert_equal "",@client.get("test5")[0].to_s.chomp
       end

       it "Append exisiting key" do
         @client.set("test5","testing",0,8)
         @client.append("test5","hb")
         assert_equal "VALUE test5 8 9 testinghb",@client.get("test5")[0].to_s.chomp
       end
     end

     describe "Cas command" do
       it "Cas non existing key" do
         @client.cas("test6","abc",3,0,8)
         assert_equal "",@client.get("test6")[0].to_s.chomp
       end
       it "Exisiting key with correct cas_unique value" do
         @client.set("test7","testing",0,8)
         cas_unique = @client.gets("test7")[0].cas_unique
         @client.cas("test7","abc",cas_unique,0,8)
         assert_equal "VALUE test7 8 3 abc",@client.get("test7")[0].to_s.chomp
       end
       it "Existing key with incorrect cas_unique value" do
         @client.set("test8","testing",0,8)
         cas_unique = @client.gets("test8")[0].cas_unique
         @client.set("test8","testing",0,8)
         @client.cas("test8","abc",cas_unique,0,8)
         assert_equal "VALUE test8 8 7 testing",@client.get("test8")[0].to_s.chomp
       end
     end
   end

end
