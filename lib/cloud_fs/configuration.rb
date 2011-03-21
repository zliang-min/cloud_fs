# -*- encoding: utf-8 -*-

module CloudFS
  # A flex configuration class.
  # @example
  #   config = CloudFS::Configuration.new
  #
  #   config.foo = 'foo'
  #   config.bar 'bar'
  #   config.baz 'a', 'b'
  #   config.before_save do
  #     "This is a before-save-block."
  #   end
  #
  #   config #=> {:foo => 'foo', :bar => 'bar', :baz => ['a', 'b'], :before_save => #<Proc>}
  class Configuration < Hash
    def self.load_file(file)
      config = new
      config.instance_eval File.read(file), file, 1 if File.file?(file)
      config
    end

    private
      def method_missing(method, *args, &blk)
        if !args.empty? && block_given?
          super
        elsif args.empty? && !block_given? && method.to_s !~ /=\z/
          send :[], method
        else
          method = method.to_s[0...-1].to_sym if method.to_s =~ /=\z/
          arg = args.size == 1 ? args.first : args.empty? && blk || args
          send :[]=, method, arg
        end
      end
  end
end
