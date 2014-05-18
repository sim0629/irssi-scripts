#!/usr/bin/perl

use Encode;
use HTTP::Request;
use LWP::UserAgent;
use Mojo::DOM;

sub exchange {
    my $text = shift;

    my $request = HTTP::Request->new(GET => "http://m.exchange.daum.net/mobile/exchange/exchangeConverter.daum");

    my $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.0");

    my $response = $ua->request($request);
    return "fail" unless($response->is_success);

    my $response_string = $response->decoded_content;

    my $dom = Mojo::DOM->new;
    $dom->parse($response_string);

    my $result = $dom->at("main#daumContent script:nth-child(2)")->all_text;

    my @ex_matches = ($result =~ m/\bex\b\[\d+\]\s*=\s*['"].+?['"]/g);
    foreach my $ex (@ex_matches) {
        eval("\$${ex}");
    }
    my @k_ex_matches = ($result =~ m/\bk_ex\b\[\d+\]\s*=\s*['"].+?['"]/g);
    foreach my $k_ex (@k_ex_matches) {
        eval("\$${k_ex}");
    }
    my @full_k_ex_matches = ($result =~ m/\bfull_k_ex\b\[\d+\]\s*=\s*['"].+?['"]/g);
    foreach my $full_k_ex (@full_k_ex_matches) {
        eval("\$${full_k_ex}");
    }
    my @ex_rate_matches = ($result =~ m/\bex_rate\b\[\d+\]\s*=\s*['"].+?['"]/g);
    foreach my $ex_rate (@ex_rate_matches) {
        eval("\$${ex_rate}");
    }
    my @country_matches = ($result =~ m/\bcountry\b\[\d+\]\s*=\s*['"].+?['"]/g);
    foreach my $country (@country_matches) {
        eval("\$${country}");
    }

    my $total_count = @ex_rate;
    for(my $i = 0; $i < $total_count; $i++) {
        if($ex[$i] =~ /${text}/i
            || $full_k_ex[$i] eq $text
            || $country[$i] eq $text) {
            return $ex_rate[$i];
        }
    }

    return "not found";
}

sub main {
    my $text = shift;
    $text = Encode::decode("utf8", $text);
    if($text =~ /^\s*(\d+(\.\d*)?)?\s*(\S+)\s*$/) {
        my $amount = 1;
        $amount = $1 if($1);
        $text = $3;
        my $result = exchange($text);
        $result *= $amount if($result ne "not found");
        return "[${amount} ${text}] ${result}";
    }else {
        return "[${text}] what the fox say";
    }
}

sub event_privmsg {
    my ($server, $data, $nick, $address) = @_;
    my ($target, $text) = split(/ :/, $data, 2);
    $target = $nick if($target !~ /^#/);
    return unless($text =~ /환율\?\s*(.+)/);
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
