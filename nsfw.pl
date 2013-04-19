use Irssi;
use Irssi::Irc;

sub nsfw {
    my ($url) = @_;
    return $url;
}

sub event_privmsg {
    my ($server, $data, $nick, $address) = @_;
    my ($target, $text) = split(/ :/, $data, 2);
    return if($target !~ /^#neria/i);
    if($text =~ /(https?:\/\/\S+)/) {
        my $test = "MSG $target ".nsfw($1).".";
        $server->command($test);
    }
}

Irssi::signal_add("event privmsg", "event_privmsg");
