use Irssi;
use Irssi::Irc;
use HTTP::Request;
use LWP::UserAgent;

sub kepco {
    my $request = HTTP::Request->new(GET => 'http://cyber.kepco.co.kr/kepco_new/library/jsp/elec.jsp');
    my $ua = LWP::UserAgent->new;
    $ua->agent('Mozilla/5.0');
    my $response = $ua->request($request);
    if ($response->is_success) {
        my $string = $response->decoded_content;
        @matches = ();
        push (@matches, $1) while ($string =~ /name="([^"]+)"/g);
        return join(" ", @matches)
    }
    return "fail"
}

sub event_privmsg {
    my ($server, $data, $nick, $address) = @_;
    my ($target, $text) = split(/ :/, $data, 2);
    $target = $nick if($target !~ /^#/);
    my $test = "MSG $target ".kepco.".";
    $server->command($test) if ($text =~ /전력량\?/);
}

Irssi::signal_add("event privmsg", "event_privmsg");
