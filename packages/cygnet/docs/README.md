# Cygnet

`cygnet` is currently comprised of two parts:

1. An implementation of the [Null Object Pattern](https://en.wikipedia.org/wiki/Null_Object_pattern), which automatically accounts for nil.

2. An implementation of collections.


## Usage

    $ rails c
    [1] pry(main)> something = Cygnet::NullObject.new
    => <#Cygnet::NullObject ...>
    [2] pry(main)> something.doesnotexist
    => <#Cygnet::NullObject ...>

    [3] pry(main)> collection = Cygnet::PaginatedCollection.new(MyBuilderClass, [records, to, put, in, collection], {:page=>1, :per_page=>20})
