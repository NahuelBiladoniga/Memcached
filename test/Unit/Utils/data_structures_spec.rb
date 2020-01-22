  require "minitest/autorun"
require_relative "../../../lib/Utils/data_structures"

describe Cache do
  before do
    @cache = Cache.new
  end

  describe "set command" do
    it "non existing key" do
    @cache.insert("set","test1",124,0,3,"abc")
      assert_equal  "VALUE test1 124 3\r\nabc\r\n",@cache.get_values(false,["test1"])[0]
    end
    it "existing previous key" do
      @cache.insert("set","test1",124,0,3,"abc")
      @cache.insert("set","test1",223,0,5,"testB")
      assert_equal  "VALUE test1 223 5\r\ntestB\r\n",@cache.get_values(false,["test1"])[0]
    end
  end

  describe "add command" do
    it "non existing key" do
      @cache.insert("add","test1",124,0,3,"abc")
      assert_equal  "VALUE test1 124 3\r\nabc\r\n",@cache.get_values(false,["test1"])[0]
    end
    it "existing previous key" do
      @cache.insert("set","test1",124,0,3,"abc")
      @cache.insert("add","test1",223,0,5,"testB")
      assert_equal  "VALUE test1 124 3\r\nabc\r\n",@cache.get_values(false,["test1"])[0]
    end
  end

  describe "replace command" do
    it "non existing key" do
      @cache.insert("replace","test1",124,0,3,"abc")
      assert_nil @cache.get_values(false,["test1"])[0]
    end
    it "existing previous key" do
      @cache.insert("add","test1",124,0,3,"abc")
      @cache.insert("replace","test1",223,0,5,"testB")
      assert_equal  "VALUE test1 223 5\r\ntestB\r\n",@cache.get_values(false,["test1"])[0]
    end
  end

  describe "cas command" do
    it "non existing key" do
      @cache.insert("cas","test1",124,0,3,"abc",3)
      assert_nil @cache.get_values(false,["test1"])[0]
    end
    it "existing key with correct cas_unique value" do
      @cache.insert("add","test1",124,0,3,"abc")
      cas_unique = @cache.get_values(true,["test1"])[0].split(" ")[4].to_i
      @cache.insert("cas","test1",421,0,9,"testB",cas_unique)
      assert_equal  "VALUE test1 421 9\r\ntestB\r\n",@cache.get_values(false,["test1"])[0]
    end
    it "existing key with incorrect cas_unique value" do
      @cache.insert("add","test1",124,0,3,"abc")
      cas_unique = @cache.get_values(true,["test1"])[0].split(" ")[4].to_i
      @cache.insert("replace","test1",223,0,5,"testB")
      @cache.insert("cas","test1",6324,0,7,"testing",cas_unique)
      assert_equal  "VALUE test1 223 5\r\ntestB\r\n",@cache.get_values(false,["test1"])[0]
    end
  end

  describe "prepend command" do
    it "non existing key" do
      @cache.concat_data("prepend","testing",5,"wrong")
      assert_nil @cache.get_values(false,["testing"])[0]
    end
    it "existing previous key" do
      @cache.insert("add","test1",124,0,3,"abc")
      @cache.concat_data("prepend","test1",2,"ok")
      assert_equal  "VALUE test1 124 5\r\nokabc\r\n",@cache.get_values(false,["test1"])[0]
    end
  end

  describe "append command" do
    it "non existing key" do
    @cache.concat_data("append","testing",5,"wrong")
      assert_nil @cache.get_values(false,["testing"])[0]
    end
    it "existing previous key" do
      @cache.insert("add","test1",124,0,3,"abc")
      @cache.concat_data("append","test1",2,"ok")
      assert_equal  "VALUE test1 124 5\r\nabcok\r\n",@cache.get_values(false,["test1"])[0]
    end
  end

  describe "time checker" do
    it "key should stay before time passed" do
      @cache.insert("set","test1",124,5,3,"abc")
      sleep 3
      assert_equal  "VALUE test1 124 3\r\nabc\r\n",@cache.get_values(false,["test1"])[0]
    end
    it "key should disappear after time with memory crawler" do
      @cache.insert("set","test1",124,2,3,"abc")
      sleep 5
      assert_nil @cache.get_values(false,["test1"])[0]
    end
    it "key should disappear after time because of get command" do
      @cache.insert("set","test1",124,2,3,"abc")
      sleep 3
      assert_nil @cache.get_values(false,["test1"])[0]
    end

  end

end
