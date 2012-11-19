# Recovering from segfaults in Ruby

Did you know you can recover from a Segmentation Fault in pure Ruby?

Here's the trick - this code is taken from the `rb_vm_bugreport` function:

    \c
    fprintf(stderr, "* Loaded script: %s\n", StringValueCStr(vm->progname));
    fprintf(stderr, "\n");
    fprintf(stderr, "* Loaded features:\n\n");
    for (i=0; i<RARRAY_LEN(vm->loaded_features); i++) {
        fprintf(stderr, " %4d %s\n", i, StringValueCStr(RARRAY_PTR(vm->loaded_features)[i]));
    }
    fprintf(stderr, "\n");

Spotted it yet?

Part of the debugging information Ruby outputs when a segfault occurs is a list of all loaded scripts and C extensions. It does this by iterating over `$LOADED_FEATURES` (or `vm->loaded_features` as it's known inside MRI), converting each item to a string and printing it to stderr.

Knowing this, we can arrange for our own code to be executed by the segfault handler by playing around with `$LOADED_FEATURES`:

    \ruby
    def protect_from_segfault
      o = Object.new
      def o.to_str; throw :recover_from_segfault end
      
      $LOADED_FEATURES << o
      catch(:recover_from_segfault) { yield }
      $LOADED_FEATURES.delete o
    end

We'll use RubyInline to create a C function that will write to a null pointer when it is called:

    \ruby
    require "inline"
    
    module Segfault
      inline do |builder|
        builder.c <<-C
          void boom() {
            *(int*)NULL = 123;
          }
        C
      end
      module_function :boom
    end

Let's give it a shot:

    \ruby
    puts "About to segfault\n\n"
    protect_from_segfault do
      Segfault.boom
    end
    puts "\n\nKeep on truckin' Ruby!"

Running that bit of code gives me this output:

    \text
    λ ruby recover-segfault.rb 
    About to segfault
    
    recover-segfault.rb:25: [BUG] Segmentation fault
    ruby 2.0.0dev (2012-11-01 trunk 37411) [x86_64-darwin11.4.0]
    
    -- Control frame information -----------------------------------------------
    c:0007 p:---- s:0019 e:000018 CFUNC  :boom
    c:0006 p:0011 s:0016 e:000015 BLOCK  recover-segfault.rb:25
    c:0005 p:0004 s:0014 e:000013 BLOCK  recover-segfault.rb:6 [FINISH]
    c:0004 p:---- s:0012 e:000011 CFUNC  :catch
    c:0003 p:0047 s:0008 e:000007 METHOD recover-segfault.rb:6
    c:0002 p:0044 s:0004 e:000598 EVAL   recover-segfault.rb:26 [FINISH]
    c:0001 p:0000 s:0002 e:001718 TOP    [FINISH]
    
    ... snip ...
    
    Keep on truckin' Ruby!