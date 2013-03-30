# Things that clear Ruby's method cache

For performance reasons, dynamic language implementations often make use of 'inline method caching' - a technique that reduces the need to constantly look up same methods over and over again.

Method caching is effective because most callsites in programs (even those written in dynamic languages) tend to be monomorphic - that is, they only ever deal with receivers of the same type.

For example, see this simple Ruby program:

    \ruby
    class Foo
      def bar
      end
    end

    1_000_000.times do
      foo = Foo.new
      foo.bar
    end

In the first iteration of the loop, both callsites are in an uninitialized state. When the Ruby VM hits these callsites, it performs a method lookup and then saves a pointer to the method inline in the bytecode.

On each subsequent iteration, because the class of the receiver in both method calls never changes, the Ruby VM can avoid performing another expensive method lookup and can call the cached method directly.

Of course, these inline method caches are not always going to remain valid, so the VM needs a way to clear invalid caches. In MRI Ruby, this is done by putting a counter on each inline cache. Before a cache is used, its counter is compared to the VM's global counter. When an operation that could potentially invalidate some inline caches is performed, MRI increments this global counter, thereby invalidating every single inline method cache.

Avoiding these operations at runtime is critical to writing fast Ruby code, so I've tried to document everything that invalidates the method caches here in the hope that this information will be useful for programmers trying to squeeze every drop of performance out of Ruby.

If you notice a place where the method caches are invalidated that I've missed here, please let me know!

### Defining new methods

Because defining a new method could potentially invalidate a method cache, MRI Ruby increments the global state counter when this happens.

    \ruby
    def foo
    end

    o = Object.new
    def o.singleton
    end

### Aliasing or removing methods

Aliasing and removing methods also invalidates the method caches, for the same reasons as defining a method. Every line in the code sample below will clear all method caches:

    \ruby
    alias say puts

    Kernel.send :alias_method, :say, :puts

    undef puts

    Kernel.send :remove_method, :puts

### Setting and removing constants

This may come as a slight surprise, but setting a new constant and removing existing constants will also invalidate the method caches. This is because MRI Ruby reuses its method caching infrastructure to cache constant lookups as well.

    \ruby
    FOO = "bar"

    Object.const_set :FOO, "bar"

    Object.send :remove_const, :Kernel

### Defining a class/module

Defining a new class/module with the `class`/`module` keywords will clear all method caches. Surprisingly, reopening an existing class/module will also cause an invalidation. In addition, opening an object's singleton class with `class <<` will invalidate the method caches.

    \ruby
    class A
    end

    module B
    end

    class Object # reopening Object
    end

    class << "some string"
    end

### Module including, prepending and extending

Including a module into a class will clear Ruby's method caches. The same goes for `Object#extend`, which is just a shortcut for including a module into the singleton class of an object.

    \ruby
    class A
      include Enumerable
    end

    class B
      prepend SomeModule
    end

    module SomeModule
      append_features C
      prepend_features D
    end

    "some string".extend(MyModule)

### Using a refinement

The `using` keyword to activate a set of refinements in the current file's scope will invalidate Ruby's method cache:

    \ruby
    using MyRefinement

### Garbage collecting a class or module

When a `Class` or `Module` object is garbage collected, Ruby forces a global invalidation. This surprised me at first, but it is indeed necessary. For example, consider the case where a class with one or more method caches pointing to it is freed by the GC. If another class is allocated at the same memory location, this could cause an incorrect cache hit.

    \ruby
    Class.new
    GC.start # invalidates method caches when the class allocated above is freed

### Changing the visibility of a constant

Starting with Ruby 1.9.3, it is now possible to change the visibility of a constant. This is possible through `Module#private_constant` and `Module#public_constant`. Both of these methods will cause an invalidation of the method caches.

    \ruby
    module A
      X = 1

      private_constant :X # invalidates

      public_constant  :X # invalidates
    end

### Marshal loading an extended object

Ruby's Marshal is able to dump objects that have been extended or prepended. When these objects are loaded back up, Ruby unsurprisingly clears the method caches.

    \ruby
    module M
    end

    o = Object.new
    o.extend M
    Marshal.dump o # => "\x04\be:\x06Mo:\vObject\0"

    Marshal.load "\x04\be:\x06Mo:\vObject\0" # invalidates

### Autoload

Registering a constant for autoload in Ruby sets the constant with a special 'undefined' value behind the scenes. This causes a method cache invalidation for the same reasons as setting a constant normally:

    \ruby
    module Foo
      autoload :Bar, "foo/bar" # invalidates
    end

### Non-blocking methods

Ruby's IO system has a collection of methods that are non-blocking. For example, `IO#read_nonblock`, `IO#readpartial`, `IO#write_nonblock`, `Socket#connect_nonblock`, `Socket#recvfrom_nonblock`, `Socket#accept_nonblock`, and many others.

In some cases, these methods raise exceptions extended with `IO::WaitWritable` or `IO::WaitReadable`. Unfortunately, the exceptions are extended with these modules every time they are raised - invalidating every method cache.

    \ruby
    $stdin.read_nonblock(1024) # raises Errno::EAGAIN extended with IO::WaitReadable
