# Changing the superclass of a class in Ruby

`dup` is an interesting method. While looking into a strange bug currently on Ruby's issues tracker [caused by the interplay of modules and dup](http://bugs.ruby-lang.org/issues/7107), I decided to take a dive into the MRI source to find out exactly what happens behind the scenes when `dup` is called. This led to the discovery of quite an interesting bug, which I will detail below.

Here's the code to `Kernel#dup` - with the exception of `Proc` and `Binding`, which override `dup` with their own implementations, this is the method called whenever you call the `dup` method on any object in Ruby.

First, it checks that the object being duped is not a 'special const' - a Fixnum, Symbol, true, false or nil (and in some cases Floats, but that's a story for another day). These are values in Ruby that act like objects but aren't actually. They can't hold singleton methods or any instance-specific state and they cannot be duped.

It then allocates a new object of the same class as `obj`, calls `init_copy()` on the new object and the original object, and then calls the `initialize_dup` method.

    \c
    VALUE
    rb_obj_dup(VALUE obj)
    {
        VALUE dup;
    
        if (rb_special_const_p(obj)) {
            rb_raise(rb_eTypeError, "can't dup %s", rb_obj_classname(obj));
        }
        dup = rb_obj_alloc(rb_obj_class(obj));
        init_copy(dup, obj);
        rb_funcall(dup, id_init_dup, 1, obj);
    
        return dup;
    }

`init_copy()` is not so interesting, so I won't bother to include its source here. It checks that the new object is not frozen, and then propagates through flags from the original object such as the taint and trust status. When duping classes or modules, `init_copy()` replaces the instance variable table on the clone with a copy of the original object's and removes the constant table.

The real interesting part is when `initialize_dup` is called on the clone with the original object as an argument. The default `initialize_dup` implementation on `Kernel` just forwards the call on to `initialize_copy`.

This is what `Class#initialize_copy` looks like:

    \c
    VALUE
    rb_class_init_copy(VALUE clone, VALUE orig)
    {
        if (orig == rb_cBasicObject) {
            rb_raise(rb_eTypeError, "can't copy the root class");
        }
        if (RCLASS_SUPER(clone) != 0 || clone == rb_cBasicObject) {
            rb_raise(rb_eTypeError, "already initialized class");
        }
        if (FL_TEST(orig, FL_SINGLETON)) {
            rb_raise(rb_eTypeError, "can't copy singleton class");
        }
        return rb_mod_init_copy(clone, orig);
    }

It performs a few type checks - ensuring you can't dup `BasicObject`, not allowing you to call `initialize_copy` on an initialized class, and not allowing you to dup a singleton class - before calling into `rb_mod_init_copy` to perform the real work of initializing the cloned class - think of this as a `super` call.

`rb_mod_init_copy` is quite long so I won't include it all, but instead I'll just show you some key lines:

    \c
    VALUE
    rb_mod_init_copy(VALUE clone, VALUE orig)
    {
        rb_obj_init_copy(clone, orig);
        /* ... */
        RCLASS_SUPER(clone) = RCLASS_SUPER(orig);
        /* ... */
        /* ... */
        return clone;
    }

`rb_obj_init_copy` is called with the same arguments received by `rb_mod_init_copy` (think of this as a `super` call at the beginning of a method), then as part of the initialization, the clone receives the same superclass as the original object. Critically, this step is performed after the type checks in `rb_class_init_copy`.

This bug basically boils down to a [time of check to time of use](http://en.wikipedia.org/wiki/Time_of_check_to_time_of_use) bug. If the type checks are performed in `Class#initialize_copy` and the initialization of the cloned class is performed later in `Module#initialize_copy`, then we can stop the type checks from executing without stopping the initialization. We can do this by redefining `Class#initialize_copy` with a call to `super`:

    \ruby
    class Class
      def initialize_copy(*)
        super
      end
    end

Now the type checks are subverted, we can reinitialize any class using another as a template. For example:

    \ruby
    class A; end
    class B < A; end
    
    class C; end
    class D < C; end
    
    puts B.superclass # => A
    
    # reinitialize B using D as a 'template', which involves copying the superclass over:
    B.send :initialize_copy, D
    
    puts B.superclass # => C

The trick is that if we want to change the superclass of a given class, we must call `initialize_copy` on it with a subclass of the desired superclass. To make this work properly, we also need to nuke the method caches, or else methods from the old superclass will continue to be called after changing the superclass. Luckily, we can force MRI Ruby to invalidate every method cache by defining a singleton method on a throwaway object. Here's an example of how I'd put together a `Class#superclass=` method using these techniques:

    \ruby
    class Class
      def superclass=(klass)
        initialize_copy(Class.new(klass))
        kludge = Object.new
        def kludge.foobar; end
      end
    end

This reinitialization has some other side effects that I won't discuss right now, but it does work well enough for this script to run:

    \ruby
    class A
      def foo
        puts "in A"
      end
    end
    
    class B
      def foo
        puts "in B"
      end
    end
    
    class C < A; end
    
    C.new.foo # outputs "in A"
    
    C.superclass = B
    
    C.new.foo # outputs "in B"

[Some members of the Ruby community](http://viewsourcecode.org/why/redhanded/inspect/SymbolIs_aString.html) want to see Symbol as a subclass of String. This is totally possible (and *highly* dangerous) with this hack:

    \ruby
    Symbol.superclass = String
    p Symbol.ancestors # outputs [Symbol, String, Comparable, Object, Kernel, BasicObject]
    puts :boom # segfault!

The fix for this subtle bug is already in Ruby trunk and at time of writing it is being backported to 1.9.3. It should go without saying, but please never use code like this seriously - as cool and fun as it may be!
