#!perl -w

# $Id: test.t,v 1.4 2002/08/27 06:22:52 moseley Exp $

use strict;
require Text::Aspell;

my $lastcase = 18;
print "1..$lastcase\n";

######################################################################
# Demonstrate the base class.


{ # Check scoping
        no strict 'vars';
        package Text::Aspell::test;
        @ISA = 'Text::Aspell';
        sub DESTROY { print "ok 1 destroyed by out of scope\n"; Text::Aspell::DESTROY(@_) }
        my $a = Text::Aspell::test->new;
}
print "ok 2\n";

my $speller = Text::Aspell->new;
print defined $speller ? "ok 3\n" : "not ok 3\n";

exit unless $speller;

print $speller->set_option('sug-mode','fast') ? "ok 4\n" : "not ok 4 " . $speller->errstr . "\n";


#print defined $speller->create_speller ? "ok 4\n" : "not ok 4 " . $speller->errstr . "\n";

print defined $speller->print_config ? "ok 5\n" : "not ok 5 " . $speller->errstr . "\n";

my $language = $speller->get_option('lang');

print defined $language ? "ok 6\n" : "not ok 6 " . $speller->errstr . "\n";

print defined $language && $language eq 'en_US' ? "ok 7 $language\n" : "not ok 7\n";

print $speller->check('test') ? "ok 8\n" : "not ok 8 " . $speller->errstr . "\n"; 

print $speller->suggest('testt') ? "ok 9\n" : "not ok 9\n";

my @s_words = $speller->suggest('testt');
print @s_words > 2 ? "ok 10 @s_words\n" : "not ok 10\n";

print defined $speller->print_config ? "ok 11\n" : "not ok 11 " . $speller->errstr . "\n";

print $speller->add_to_session('testt') ? "ok 12\n" : "not ok 12 " . $speller->errstr . "\n";
@s_words = $speller->suggest('testt');

print '',(grep { $_ eq 'testt' } @s_words ) ? "ok 13 @s_words\n" : "not ok 13\n";

print $speller->store_replacement('foo', 'bar') ? "ok 14\n" : "not ok 14 " . $speller->errstr . "\n";

@s_words = $speller->suggest('foo');
print '',(grep { $_ eq 'bar' } @s_words ) ? "ok 15 @s_words\n" : "not ok 15\n";

print $speller->clear_session ? "ok 16\n" : "not ok 16 " . $speller->errstr . "\n";
@s_words = $speller->suggest('testt');
print '',(!grep { $_ eq 'testt' } @s_words)  ? "ok 17 @s_words\n" : "not ok 17 @s_words\n";

my @dicts = $speller->list_dictionaries;
print @dicts ? "ok 18 " . scalar @dicts . " dictionaries found\n" : "not ok 18\n";

