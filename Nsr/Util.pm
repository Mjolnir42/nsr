package Nsr::Util;

use 5.014_000;
use perl5i::2;
BEGIN {
  our $VERSION    = 0.01;

  use base          qw/Exporter/;
  our @EXPORT_OK  = qw/is_ipaddress reverse_ipv4 reverse_ipv6/;

  use constant {
    EX_OK    => 0,
    EX_ERROR => 1,
    EX_USAGE => 64,
    TRUE     => 1,
    FALSE    => 0,
  };
}

func is_ipaddress ( $input ) {
  # contains illegal characters
  return FALSE unless ( $input =~ m/^[0-9a-f:\.]+$/ix );

  # test if IPv4 address
  my $re4p = q/(?:25[0-5]|2[0-4][0-9]|[01]?[0-9]{1,2})/;
  my $re4 = qr/^$re4p(?:\.$re4p){3}$/x;
  return TRUE if ( $input =~ $re4 );

  # test if IPv6 address
  # this only detects IPv6 addresses in hexadecimal format with
  # colons, the probably most common usecase. Valid formats where
  # the last 32-bit are written in "IPv4 notation" are not supported
  return TRUE if ( $input =~ m/^::$/x );
  my $short = FALSE;
  if ( $input =~ m/(?<!:)::$/x ) { # look-behind
    $input =~ s/::$//x;
    $short = TRUE;
  }
  elsif ( $input =~ m/^::(?!:)/x ) { # look-ahead
    $input =~ s/^:://x;
    $short = TRUE;
  }
  elsif ( $input =~ m/(?<!:)::(?!:)/x ) { # look-around
    $input =~ s/::/:/x;
    $short = TRUE;
  }
  # input had :: twice or :::
  return FALSE if ($input =~ m/::/x);

  my $re6p = q/(?:[0-9a-f]{1,4})/;
  my $re6 = ( $short == TRUE )
          ? qr/^$re6p(?::$re6p){0,6}$/ix
          : qr/^$re6p(?::$re6p){7}$/ix;
  return TRUE if ( $input =~ $re6 );
  # did not conform to our narrow view of what an IPv4 or IPv6
  # address looks like -- might still be one!
  return FALSE;
}

func reverse_ipv4 ( $ip4addr ) {
  return $ip4addr->split(q/\./)->reverse->join(q/./);
}

func reverse_ipv6 ( $ip6addr ) {
  # convert IPv6 address into fully expanded notation,
  # then reverse the order. This here only works for hexadecimal
  # notation with colons, not every valid IPv6 format
  my @groups = $ip6addr->split(q/:/);
  my @expanded;

  # Account for the various number of empty entries in @groups
  # depending on where in the address the :: was.
  # Hic sunt dracones.
  my $zeroblocks = 8 - scalar @groups;
  my $i = 0;
  if ( $ip6addr =~ /^::/x ) {
    $zeroblocks += 2;
  }
  elsif ( $ip6addr =~ /::/x ) {
    ++$zeroblocks;
  }

  # Expand short hex groups with leading zeros, fill the first
  # :: we encounter. This is only mildly dangerous in our case
  # because is_ipaddress() rejects addresses with multiple ::
  # sequences
  @groups->foreach(
    func ( $element ) {
      unless ( $element eq "" ) {
        @expanded->push( sprintf( "%04s", lc( $element ) ) );
      }
      else {
        while ( $i < $zeroblocks ) {
          @expanded->push( q/0000/ );
          ++$i;
        }
      }
    }
  );
  # fill trailing zero blocks if the address ended in :: or is ::
  # this case creates no empty string element in @groups and does
  # not trigger the fill loop above
  for ( my $j = scalar @expanded; $j < 8; $j++ ) {
    @expanded->push( q/0000/ );
  }
  # merge 4-char blocks, split into single characters, reverse
  # and join by adding . inbetween
  return @expanded->join(q//)->split(q//)->reverse->join(q/./);
}
