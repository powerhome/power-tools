# Something for Nothing

`something_for_nothing` is currently comprised of two parts:

1. An implementation of the [Null Object Pattern](https://en.wikipedia.org/wiki/Null_Object_pattern), which automatically accounts for nil.

2. An implementation of nested hashes using [DeepStruct](http://andreapavoni.com/blog/2013/4/create-recursive-openstruct-from-a-ruby-hash).


## Usage

    $ rails c
    [1] pry(main)> something = SomethingForNothing::NullObject.new
    => <#SomethingForNothing::NullObject ...>
    [2] pry(main)> something.doesnotexist
    => <#SomethingForNothing::NullObject ...>

    [3] pry(main)> s = SomethingForNothing::DeepStruct.new({foo: {bar: :baz}})
    => #<SomethingForNothing::DeepStruct foo=#<SometingForNothing::DeepStruct bar=:baz>>
    [4] pry(main)> s.foo
    => #<SomethingForNothing::DeepStruct bar=:baz>
    [5] pry(main)> s.foo.bar
    => :baz
    [6] pry(main)> s.bar.foo
    => #<SomethingForNothing::NullObject:0x007f974c1dc230>
