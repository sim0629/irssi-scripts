use Irssi;

sub event_privmsg {
    my ($server, $data, $nick, $address) = @_;
    my ($target, $text) = split(/ :/, $data, 2);
    return if($target !~ /^#/);
    return unless($text =~ /토픽\?/);
    my $channel = $server->channel_find($target);
    my $topic = $channel->{topic};
    $server->command("MSG ${target} ${topic}");
}

Irssi::signal_add("event privmsg", "event_privmsg");

