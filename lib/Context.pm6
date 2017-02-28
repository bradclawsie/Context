use v6;

=begin pod

=head1 NAME

A building block for concurrent programming based loosely on Go's `context`.

=head1 DESCRIPTION

Go's `context` (https://golang.org/pkg/context/) solves two important problems
for concurrent programming. First, it provides a mechanism for sharing a safe
cancellation mechanism. Second, it provides a safe abstraction for sharing
values between concurrent execution contexts.

Consider a program which spawns workers concurrently but then wants to terminate
them. The Context package provides a standard building block for providing this.

Now assume the same program encodes values into some protocol mechanism such
as HTTP headers or query parameters for spawned workers to access. The problem
with this is it results in brittleness; if a developer wishes to move some
value from a query parameter to a header, they must chase down every piece
of code that works thusly and edit it. The better approach is to eliminate
protocol details as early in the process of spawning workers entirely, and to
use a protocol-agnostic mechanism like a Context instance to communicate these
values safely to spawned workers.

It is often good practice to not make assumptions about the concurrent environment
library code will be used in, but the Context package only makes sense as a
building block for concurrent development, so it is enabled for safe use
in concurrent environments by default.

=end pod

class X::Context::KeyNotFound is Exception is export {
    has Mu $.key;
    method message() { 'not found: ' ~ $.key.gist; }
}

class X::Context::BadCopier is Exception is export {
    has Signature $.signature;
    method message() {
        'bad copy signature: ' ~ $.signature.gist ~ ' (expected: ' ~ :(Any --> Any).gist ~ ')';
    }
}

# The supply for Context may send other consumables. This is the one you should exchange
# when you want to cancel a context.
constant $CANCEL is export = 'context-cancel';

class Context:auth<bradclawsie>:ver<0.0.1> is export {
    has Hash[Mu,Any] $!kv;
    has Lock $!lock;
    has Supplier $.supplier;
    
    submethod BUILD() {
        $!kv = Hash[Mu,Any].new();
        $!lock = Lock.new();
        $!supplier = Supplier.new();
    }
    
    # Sanity check a value-copying function.
    my sub copy-val(Sub $make-copy, Any $val --> Any) {
        my Any $copy;
        if $make-copy.defined.so {
            if $make-copy.signature.params.elems != 1 ||
            $make-copy.signature.returns.elems != 1 {
                X::Context::BadCopier.new(signature=>$make-copy.signature).throw;
            }
            return $make-copy($val);
        } else {
            return $val.clone;
        }
    }
    
    # `set` a key/value in the shared hash. The value will be cloned unless
    # an optional make-copy function of Any --> Any is provided, in which
    # case it will be called.
    method set(Mu:D $key, Any $val, Sub $make-copy?) {
        my $block = {
            my Any $copy = copy-val($make-copy,$val);
            $!kv.append(:{($key) => $copy});
        }
        $!lock.protect($block);
    }
    
    # `get` a value in the shared hash. The value will be cloned unless
    # an optional make-copy function of Any --> Any is provided, in which
    # case it will be called. An exception of type X::Context::KeyNotFound
    # is thrown upon a key not being set in the shared hash.
    method get(Mu:D $key, Sub $make-copy? --> Any) {
        my $block = {
            if $!kv{$key}:exists {
                return copy-val($make-copy,$!kv{$key});     
            } else {
                X::Context::KeyNotFound.new(key=>$key).throw;
            }
        }
        $!lock.protect($block);
    }
    
    # `canceler` returns a sub you can call to force the context to canel.
    method canceler(--> Sub) {
        return sub {
            $!supplier.emit($CANCEL);
        }
    }
}

