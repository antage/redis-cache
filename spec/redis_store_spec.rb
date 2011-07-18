require "active_support"

describe "ActiveSupport::Cache::RedisStore" do
  let!(:redis_options) do
    {
      :host => "localhost",
      :port => 6379,
      :db => 0
    }
  end

  context "ActiveSupport::Cache.lookup_store :redis_store with options" do
    subject { lambda { ActiveSupport::Cache.lookup_store :redis_store, redis_options } }

    it "should not raise any exceptions" do
      should_not raise_error
    end

    it "should return instance of ActiveSupport::Cache::RedisStore" do
      subject.call.should be_instance_of(ActiveSupport::Cache::RedisStore)
    end
  end

  context "instance" do
    let!(:store) { ActiveSupport::Cache.lookup_store :redis_store, redis_options }

    before(:each) do
      store.clear
    end
    
    context "#clear" do
      before(:each) do
        store.write("abc_entity", "test")
        store.clear
      end

      it "should clear store" do
        store.read("abc_entity").should be_nil
      end
    end
    
    context "with key 'abc' consisting 'test'" do
      before(:each) do
        store.write("abc", "test")
      end

      it "should be #exist?" do
        store.exist?("abc").should be_true
      end
      
      it "should return 'test' when #read('abc')" do
        store.read("abc").should == "test"
      end
    end

    context "without any keys, #read_multi" do
      before(:each) { store.clear }
      subject { lambda { store.read_multi("a1", "a2", "a3") } }

      it "should not raise any errors" do
        should_not raise_error
      end
    end
    
    context "with keys 'a1', 'a2', 'a3', #read_multi('a1', 'a2', 'a3')" do
      before(:each) do
        store.write("a1", "test1")
        store.write("a2", "test2")
        store.write("a3", "test3")
      end

      subject { store.read_multi("a1", "a2", "a3") }

      (1..3).each do |i|
        it "should have key 'a#{i}'" do
          should be_has_key("a#{i}")
        end

        it "#['a#{i}'] should == 'test#{i}'" do
          subject["a#{i}"].should == "test#{i}"
        end
      end
    end

    context "with raw value 5 in key 'abc'" do
      before(:each) do
        store.write("abc", 5, :raw => true)
      end

      it "#read('abc') should return 5 as String" do
        store.read("abc").should be_instance_of(String)
        store.read("abc").should == "5"
      end
    end

    context "with crazy key characters" do
      let(:crazy_key) { "#/:*(<+=> )&$%@?;'\"\'`~- \t" }

      it "should write the key and should not raise any exceptions" do
        lambda { store.write(crazy_key, "test") }.should_not raise_error
      end

      it "should read the key and should not raise any exceptions" do
        lambda { store.read(crazy_key) }.should_not raise_error
      end
    end

    context "with raw key 'abc' == 5" do
      before(:each) do
        store.write("abc", 5, :raw => true)
      end

      it "#increment('abc', 2) should return 7 and change key 'abc' to 7" do
        store.increment("abc", 2).should == 7
        store.read("abc").to_i.should == 7
      end

      it "#increment('abc', 2, :expires_in => 1.hour) should return 7 and change key 'abc' to 7" do
        store.increment("abc", 2, :expires_in => 1.hour).should == 7
        store.read("abc").to_i.should == 7
      end

      it "#decrement('abc', 2) should return 3 and change key 'abc' to 3" do
        store.decrement("abc", 2).should == 3
        store.read("abc").to_i.should == 3
      end

      it "#decrement('abc', 2, :expires_in => 1.hour) should return 3 and change key 'abc' to 3" do
        store.decrement("abc", 2, :expires_in => 1.hour).should == 3
        store.read("abc").to_i.should == 3
      end
    end

    context "#delete('abc')" do
      before(:each) do
        store.write("abc", "test")
      end

      it "should delete key" do
        store.delete("abc")
        store.exist?("abc").should be_false
      end
    end

    context "#fetch('abc', ...)" do
      before(:each) do
        store.write("abc", true)
      end
      
      it "should fetch value from cache" do
        store.fetch("abc") { false }.should be_true
      end
    end
  end

  context "instances with different namespaces" do
    let(:store_ns1) { ActiveSupport::Cache.lookup_store :redis_store, redis_options.merge(:namespace => "ns1") }
    let(:store_ns2) { ActiveSupport::Cache.lookup_store :redis_store, redis_options.merge(:namespace => "ns2") }

    before(:each) do
      store_ns1.write("abc", "test1")
      store_ns2.write("abc", "test2")
    end

    it "shouldn't inteferent each to other" do
      store_ns1.read("abc").should == "test1"
      store_ns2.read("abc").should == "test2"
    end
  end
end
