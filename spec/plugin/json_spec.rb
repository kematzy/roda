require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "json plugin" do
  before do
    c = Class.new do
      def to_json
        '[1]'
      end
    end

    app(:bare) do
      plugin :json, :classes=>[Array, Hash, c]

      route do |r|
        r.is 'array' do
          [1, 2, 3]
        end

        r.is "hash" do
          {'a'=>'b'}
        end

        r.is 'c' do
          c.new
        end
      end
    end
  end

  it "should use a json content type for a json response" do
    header('Content-Type', "/array").must_equal 'application/json'
    header('Content-Type', "/hash").must_equal 'application/json'
    header('Content-Type', "/c").must_equal 'application/json'
    header('Content-Type').must_equal 'text/html'
  end

  it "should convert objects to json" do
    body('/array').gsub(/\s/, '').must_equal '[1,2,3]'
    body('/hash').gsub(/\s/, '').must_equal '{"a":"b"}'
    body('/c').must_equal '[1]'
    body.must_equal ''
  end

  it "should work when subclassing" do
    @app = Class.new(app)
    app.route{[1]}
    body.must_equal '[1]'
  end

  it "should accept custom serializers" do
    app.plugin :json, :serializer => proc{|o| o.inspect}
    body("/hash").must_equal '{"a"=>"b"}'
  end

  it "should give serializer the request if :include_request is set" do
    app.plugin :json,
      :include_request => true,
      :serializer => lambda{|o,r| "#{o['a']}:#{r.path_info}"}

    body("/hash").must_equal 'b:/hash'
  end
end
