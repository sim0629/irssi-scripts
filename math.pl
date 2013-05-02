#!/usr/bin/perl

use Math::Expression::Evaluator;

sub math {
    my $plain = shift;
    my $evaluator = Math::Expression::Evaluator->new;
    my $result = $evaluator->parse($plain)->val();
    return $result;
}

sub main {
    my $plain = shift;
    my $result = math($plain);
    return "[${plain}] ${result}";
}

sub event_privmsg {
    my ($server, $data, $nick, $address) = @_;
    my ($target, $text) = split(/ :/, $data, 2);
    $target = $nick if($target !~ /^#/);
    return unless($text =~ /계산\?(.+)?/);
    $server->command("MSG ${target} ".main($+));
}

if(caller) {
    require Irssi;
    Irssi::signal_add("event privmsg", "event_privmsg");
}else {
    binmode(STDOUT, ":utf8");
    print main(@ARGV[0]);
    print "\n";
}
