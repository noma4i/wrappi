require 'spec_helper'
module Wrappi
  describe Endpoint do
    describe 'DSL' do
      let(:client) do
        client = Class.new(Client) do
          setup do |c|
            c.domain = 'http://domain.com'
          end
        end
        klass
      end
      it 'literal methods' do
        client = Class.new(Client) do
          setup do |c|
            c.domain = 'http://domain.com'
          end
        end
        klass = Class.new(described_class) do
          client client
          verb :get
          path "/users/:id"
        end
        inst = klass.new(id: 12)
        expect(inst.verb).to eq :get
        expect(inst.path).to eq '/users/:id'
        expect(inst.url.to_s).to match '/users/12'
        expect(inst.url_with_params.to_s).to eq 'http://domain.com/users/12'
        expect(inst.cache_key).to eq "[GET]#http://domain.com/users/12"
      end

      it 'blocks as configs' do
        klass = Class.new(described_class) do
          client Dummy
          verb :post
          path do
            "/users/#{some_id}"
          end

          def some_id
            10
          end
        end

        inst = klass.new()
        expect(inst.verb).to eq :post
        expect(inst.path).to eq '/users/10'
        expect(inst.response).to be_a Wrappi::Response
        expect(inst.url_with_params.to_s).to eq inst.url.to_s
      end

      it 'default params' do
        client = Class.new(Wrappi::Client) do
          setup do |config|
            config.domain = 'https://api.github.com'
          end
        end
        def_params = { 'name' => 'foo' }
        klass = Class.new(described_class) do
          client client
          verb :get
          path "/users"
          default_params def_params
        end

        inst = klass.new()
        expect(inst.verb).to eq :get
        expect(inst.path).to eq '/users'
        expect(inst.url.to_s).to eq 'https://api.github.com/users'
        expect(inst.consummated_params).to eq def_params
        expect(inst.url_with_params.to_s).to match "name=foo"
        expect(inst.url_with_params.to_s).to match 'https://api.github.com/users'
        expect(inst.cache_key).to eq "[GET]#https://api.github.com/users?50b6137335559d7afac1144578f8e178"
      end
    end

    describe "::setup" do
      it "can modify configuration from outside with ::setup" do
        klass = Class.new(described_class) do
          client Dummy
          verb :post
          path "/users/:id"
        end

        klass.setup do
          path "v2/users/:id"
          verb :get
          async_callback do
            "hello"
          end
        end

        inst = klass.new(id: 1)
        expect(inst.url).to match "v2/users/1"
        expect(inst.verb).to eq :get
        expect(inst.send(:async_callback).call).to eq "hello"
      end
    end

    describe "inherited" do
      it 'inherits other class settings' do
        klass = Class.new(described_class) do
          client Dummy
          verb :post
          path "/users/:id"
          async_callback { "hello" }
          around_request { "hello" }
          retry_if { "hello" }
          cache_options { "hello" }
        end

        inherited = Class.new(klass) do
          path "/hello"
        end
        inst = inherited.new
        expect(inst.url).to match "/hello"
        expect(inst.verb).to eq :post
        expect(inst.send(:async_callback).call).to eq "hello"
        expect(inst.around_request.call).to eq "hello"
        expect(inst.retry_if.call).to eq "hello"
        expect(inst.cache_options.call).to eq "hello"
      end
    end

    describe '#url' do
      it 'domain has path' do
        client = Class.new(Wrappi::Client) do
          setup do |config|
            config.domain = 'https://api.github.com/foo/bar'
          end
        end
        klass = Class.new(described_class) do
          client client
          path "/users"
        end
        inst = klass.new()
        expect(inst.url.to_s).to eq 'https://api.github.com/foo/bar/users'
      end
      it 'domain has path and trailing /' do
        client = Class.new(Wrappi::Client) do
          setup do |config|
            config.domain = 'https://api.github.com/foo/bar/'
          end
        end
        klass = Class.new(described_class) do
          client client
          path "/users"
        end
        inst = klass.new()
        expect(inst.url.to_s).to eq 'https://api.github.com/foo/bar/users'
      end
      it 'domain has path and trailing / and path does not start with /' do
        client = Class.new(Wrappi::Client) do
          setup do |config|
            config.domain = 'https://api.github.com/foo/bar/'
          end
        end
        klass = Class.new(described_class) do
          client client
          path "users"
        end
        inst = klass.new()
        expect(inst.url.to_s).to eq 'https://api.github.com/foo/bar/users'
      end
    end
  end
end
