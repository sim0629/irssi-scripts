use Irssi;
use Irssi::Irc;
use strict;

my @colors = qw/15 3 4 5 6 7 9 10 11 12 13/;

sub simple_hash {
    my ($string) = @_;
    chomp $string;
    my @chars = split //, $string;
    my $counter;    
    foreach my $char (@chars) {
        $counter += ord $char;
    }
    $counter = $colors[$counter % 11];
    return $counter;
}

sub on_pubmsg {
    my ($server, $msg, $nick, $address, $target) = @_;
    if($msg =~ m/^<([\ \+@])([^>]+)> (.+)$/) {
        $msg = "\x0314<\x0f".$1."\x03".simple_hash($2).$2."\x0314>\x0f ".$3;
    }
    Irssi::signal_continue($server, $msg, $nick, $address, $target);
}

Irssi::signal_add("message public", "on_pubmsg");
