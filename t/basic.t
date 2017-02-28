use v6;
use Test;
use Context;

subtest {
    lives-ok {
        my $c = Context.new();
        $c.set('a','b');
        $c.set('c','d',sub (Str $s --> Str) { return $s.clone; });
        my $canceler = $c.canceler();
    }, 'basic';
}, 'construct';

done-testing;
