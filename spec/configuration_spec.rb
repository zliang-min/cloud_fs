# -- encoding: utf-8 --

#require File.join(File.dirname(__FILE__), 'helper')
require 'helper'

describe CloudFS::Configuration do
  subject { CloudFS::Configuration.new }

  specify {
    subject.foo 'foo'
    subject.foo.should == 'foo'
  }

  specify {
    subject.foo false
    subject.foo.should be false
  }

  specify {
    subject.foo true
    subject.foo.should be true
  }

  specify {
    subject.foo 'something'
    subject.foo nil
    subject.foo.should be_nil
  }

  specify {
    subject.foo { 'a block' }
    subject.foo.should be_instance_of(Proc)
  }

  specify {
    subject.foo 'a', 'b'
    subject.bar ['a', 'b']
    subject.foo.should == subject.bar
  }

  specify {
    lambda { subject.foo('a', 'b') { 'block' } }.should raise_exception(NoMethodError)
  }
end

