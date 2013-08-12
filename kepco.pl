#!/usr/bin/perl

use utf8;
use Encode;
use HTTP::Request;
use JSON;
use LWP::UserAgent;

sub kepco {
    my $request = HTTP::Request->new(GET => 'http://cyber.kepco.co.kr/kepco/main/getNewGraph.json');
    my $ua = LWP::UserAgent->new;
    $ua->agent('Mozilla/5.0');
    my $response = $ua->request($request);
    if ($response->is_success) {
        my $string = $response->decoded_content;
        my $json = decode_json($string);
        my $result = $json->{"mainVO"};
        return $result->{"currentDate"}
            ." 최대전력:"
            .$result->{"totalValue"}
            ."만kW 예비전력:"
            .$result->{"reserveValue"}
            ."만kW 예비율:"
            .$result->{"reservePercent"}
            ."% "
            .$result->{"frequencyVal"};
    }
    return "fail"
}

sub event_privmsg {
    my ($server, $data, $nick, $address) = @_;
    my ($target, $text) = split(/ :/, $data, 2);
    $target = $nick if($target !~ /^#/);
    $text = Encode::decode("utf8", $text);
    if($text =~ /전력량\?/) {
        my $test = "MSG $target ".kepco.".";
        $server->command($test);
    }
}

if(caller) {
    require Irssi;
    Irssi::signal_add("event privmsg", "event_privmsg");
}else {
    binmode(STDOUT, ":utf8");
    print kepco;
    print "\n";
}
