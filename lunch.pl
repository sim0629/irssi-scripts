#!/usr/bin/perl

use HTTP::Request;
use LWP::UserAgent;
use Mojo::DOM;

sub menu {
  my $request = HTTP::Request->new(GET => "http://mini.snu.kr/cafe/today/jk");
  my $ua = LWP::UserAgent->new;
  $ua->agent("Mozilla/5.0");
  my $response = $ua->request($request);
  return "fail" unless($response->is_success);
  my $response_string = $response->decoded_content;
  my $dom = Mojo::DOM->new;
  $dom->parse($response_string);
  my $m301 = $dom->at("div#main > table > tr:nth-child(3)")->all_text;
  my $m302 = $dom->at("div#main > table > tr:nth-child(4)")->all_text;
  return $m301."\n".$m302;
}

sub event_privmsg {
  my ($server, $data, $nick, $address) = @_;
  my ($target, $text) = split(/ :/, $data, 2);
  $target = $nick if($target !~ /^#/);
  return unless($text =~ /점심\?/);
  my ($m1, $m2) = split("\n", menu);
  $server->command("MSG ${target} ${m1}");
  $server->command("MSG ${target} ${m2}");
}

if(caller) {
  require Irssi;
  Irssi::signal_add("event privmsg", "event_privmsg");
}else {
  binmode(STDOUT, ":utf8");
  print menu;
  print "\n";
}
