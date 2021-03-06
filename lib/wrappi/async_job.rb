module Wrappi
  module AsyncConcern
    def wrappi_perform(endpoint_class, args, options)
      @endpoint_class = endpoint_class
      @args = parse(args)
      @options = parse(options)
      return unless endpoint_const
      inst = endpoint_const.new(@args[:params], @args[:options])
      inst.perform_async_callback(@options)
    end

    private

    def parse(data)
      return ia(data) if data.is_a?(Hash)
      ia(JSON.parse(data)) rescue {}
    rescue
      data
    end

    def ia(data)
      Fusu::HashWithIndifferentAccess.new(data)
    end

    def endpoint_const
      Class.const_get(@endpoint_class)
    rescue
      puts "[Wrappi] Unable to find const #{@endpoint_class} for async"
      false
    end
  end
if defined?(ActiveJob)
  class Async < ActiveJob::Base
    include AsyncConcern
    def perform(*args)
      wrappi_perform(*args)
    end
  end
else
  class AsyncJob
    include AsyncConcern
    def self.set(options = {})
      self
    end
    def self.perform_later(*args)
      puts "Unable to perform async ActiveJob is not installed"
      new().wrappi_perform(*args)
    end
  end
end
end
