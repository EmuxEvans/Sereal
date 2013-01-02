#!perl 
use strict;
use warnings;
use Test::More;
use Sereal::Encoder;
use Sereal::Decoder;

# Regression test for issue 15 on github:
# https://github.com/Sereal/Sereal/issues/15

# Snappy compression was broken by assuming remaining document length
# is the same as compressed-data-length.

my $encoder = Sereal::Encoder->new( { snappy => 1, snappy_threshold => 1 } );
my $decoder = Sereal::Decoder->new();

# establish base behaviour
ok( $decoder->decode($encoder->encode("foo")), 'normal decode' );

# build test string with data after first document
my $str;
foreach my $i (0..1) {
    $str .= $encoder->encode("foo");
}

ok( _decode_with_offset($str), 'decode with offset' );

sub _decode_with_offset {
    my ($value) = @_;

    my @decoded_values;
    my $pos = 0;
    #my $first = index($value, "=srl", 1);
    #$value = substr($value, 0, $first);
    my $ok = eval {
        while ($pos < length($value)) {
            push @decoded_values, $decoder->decode_with_offset($value, $pos);
            last if $decoder->bytes_consumed == 0;
            $pos += $decoder->bytes_consumed;
        }
        1;
    };
    my $err = $@;
    ok($ok, "decoding did not die")
        or diag("Exception: $err"), return;

    return \@decoded_values;
}

done_testing;