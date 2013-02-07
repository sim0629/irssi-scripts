#!/usr/bin/perl

use HTTP::Request;
use LWP::UserAgent;
use Mojo::DOM;

sub location_code {
    my $location = shift;
    $location = "서울" unless($location);
    my %code = (
        "서울" => "CA0101",
        "인천" => "CA0104",
        "문산" => "CA0112",
        "동두천" => "CA0113",
        "수원" => "CA0120",
        "춘천" => "CA0201",
        "철원" => "CA0202",
        "원주" => "CA0207",
        "영월" => "CA0209",
        "강릉" => "CA0301",
        "대관령" => "CA0302",
        "속초" => "CA0304",
        "동해" => "CA0307",
        "대전" => "CA0401",
        "서산" => "CA0402",
        "청주" => "CA0501",
        "충주" => "CA0502",
        "추풍령" => "CA0510",
        "부산" => "CA0601",
        "울산" => "CA0602",
        "마산" => "CA0605",
        "통영" => "CA0608",
        "진주" => "CA0621",
        "대구" => "CA0701",
        "울진" => "CA0702",
        "포항" => "CA0704",
        "상주" => "CA0707",
        "안동" => "CA0712",
        "진도" => "CA0803",
        "완도" => "CA0804",
        "여수" => "CA0810",
        "광주" => "CA0815",
        "목포" => "CA0821",
        "흑산도" => "CA0825",
        "전주" => "CA0901",
        "군산" => "CA0910",
        "제주" => "CA1001",
        "서귀포" => "CA1002",
        "고산" => "CA1003",
        "울릉도" => "CA1101",
        "백령도" => "CA1201"
    );
    return $code{$location};
}

sub kma {
    my $location = shift;
    my $code = location_code($location);
    return "미지원" unless($code);
    my $request = HTTP::Request->new(GET => "http://www.w365.com/korea/kor/w365_iframe_real.html?code=${code}");
    my $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.0");
    my $response = $ua->request($request);
    return "실패" unless($response->is_success);
    my $response_string = $response->decoded_content;
    my $dom = Mojo::DOM->new;
    $dom->parse($response_string);
    return $dom->at("html > body > table")->all_text;
}

sub event_privmsg {
    my ($server, $data, $nick, $address) = @_;
    my ($target, $text) = split(/ :/, $data, 2);
    $target = $nick if($target !~ /^#/);
    return unless($text =~ /날씨\?(\ *([^\ ]+))?/);
    $server->command("MSG ${target} [${location}] ".kma($+));
}

if(caller) {
    require Irssi;
    Irssi::signal_add("event privmsg", "event_privmsg");
}else {
    binmode(STDOUT, ":utf8");
    print kma(@ARGV[0]);
    print "\n";
}
