use v6;
use Test;
use Context;

subtest {
    lives-ok {
        my $c = Context.new();
        my $canceler = $c.canceler();
    }, 'basic';
}, 'construct';

subtest {
    lives-ok {
        my $c = Context.new();
        $c.set('a','b');
        $c.set('c','d',sub (Str $s --> Str) { return $s.clone; });
        my $a-v = $c.get('a');
        is ($a-v eq 'b'), True, 'val match';
        my $c-v = $c.get('c');
        is ($c-v eq 'd'), True, 'val match';
    }, 'set/get scalar';

    lives-ok {
        class Foo { has Int $.i; has Str $.s; }
        my $cp = sub (Foo $f --> Foo) { Foo.new(i => $f.i, s => $f.s); }
        my Foo $k = Foo.new(i => 3, s => 'k');
        my Foo $v = Foo.new(i => 5, s => 'v');        
        my $c = Context.new();
        $c.set($k,$v,$cp); 
        my Foo $k-v = $c.get($k);
        is ($k-v eqv $v), True, 'val match';
    }, 'set complex type';
}, 'set/get complex type';

done-testing;
