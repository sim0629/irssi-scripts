use Irssi;
use Irssi::Irc;
use URI::Escape;

sub nsfw {
    my ($url) = @_;
    return uri_escape($url);
}

sub event_privmsg {
    my ($server, $data, $nick, $address) = @_;
    my ($target, $text) = split(/ :/, $data, 2);
    return if($target !~ /^#neria/i);
    if($text =~ /(https?:\/\/\S+)/) {
        my $test = "MSG $target http://nsfw.neria.kr/?q=".nsfw($1);
        $server->command($test);
    }
}

Irssi::signal_add("event privmsg", "event_privmsg");
