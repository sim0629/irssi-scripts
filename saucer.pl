use Irssi;
use DBI qw(:sql_types);
use HTTP::Request;
use LWP::UserAgent;
use Mojo::DOM;
use Time::HiRes;
use Try::Tiny;

my $CHANNEL = /^#jubeater$/i;
my $MAX_NUM_OF_ROWS = 5;
my $FLOOD_DELAY = 0.5;

sub fetch {
    my ($dbh, $user) = @_;
    $user =~ s/^\s+//;
    $user =~ s/\s+$//;

    my $safe_user = $dbh->quote_identifier($user);

    $dbh->do("CREATE TABLE ${safe_user} (
         id INTEGER
        ,name TEXT
        ,difficulty TEXT
        ,level INTEGER
        ,score INTEGER
        ,fullcombo INTEGER
        ,rank INTEGER
        ,delta INTEGER
    )");

    my $sth = $dbh->prepare("INSERT INTO ${safe_user} (
         id
        ,name
        ,difficulty
        ,level
        ,score
        ,fullcombo
        ,rank
        ,delta
    ) VALUES (
         ?
        ,?
        ,?
        ,?
        ,?
        ,?
        ,?
        ,?
    )");

    my $request = HTTP::Request->new(GET => "http://saucer.isdev.kr/${user}/all-default");
    my $ua = LWP::UserAgent->new;
    $ua->agent('Mozilla/5.0');
    my $response = $ua->request($request);
    return if (!$response->is_success);
    my $string = $response->decoded_content;
    my $dom = Mojo::DOM->new;
    $dom->parse($string);
    for my $tr ($dom->at('#music_list tbody')->find('tr')->each) {
        next if $tr->attrs('class') eq 'other';
        my $a_song = $tr->at('.title > a');

        my $href = $a_song->attrs('href');
        my $number = substr($href, rindex($href, '-') + 1);

        my $name = $a_song->text;

        my $difficulty_number = 0;
        for my $difficulty ('bsc', 'adv', 'ext') {
            $td = $tr->at(".${difficulty}");

            my $level = $td->at('.level')->text;

            my $score = $td->at('.score')->text;
            $score =~ s/,//g;

            my $div_bottom = $td->at('.bottom');
            my $rank = substr($div_bottom->text, 1);

            my $fullcombo = ($td->at('.mark')->text eq 'FC') ? 1 : 0;

            my $text = $td->at('.text')->text;
            my $delta = 0;
            if($text =~ /^[\+\-]([0-9,]+)/) {
                $delta = $1;
            }

            $sth->execute(
                 $number.$difficulty_number
                ,$name
                ,$difficulty
                ,$level
                ,$score
                ,$fullcombo
                ,$rank
                ,$delta
            );

            $difficulty_number += 1;
        }
    }
}

sub execute {
    my ($dbh, $command, $callback) = @_;

    my $select = $dbh->prepare($command);
    $select->execute();
    my $count = 0;
    while(my (@result) = $select->fetchrow_array()) {
        $count += 1;
        if($count <= $MAX_NUM_OF_ROWS) {
            $callback->(join(', ', @result));
        }
    }
    my $suppressed_count = $count - $MAX_NUM_OF_ROWS;
    if($suppressed_count > 0) {
        $callback->("${suppressed_count} more...");
    }
}

sub main {
    my $users_ref = shift;
    my @users = @$users_ref;
    my $command = shift;
    my $callback = shift;

    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=:memory:", "", "",
        {
            RaiseError => 1,
            sqlite_unicode => 1,
        }
    );

    for my $user (@users) {
        fetch($dbh, $user);
    }
    execute($dbh, $command, $callback);

    $dbh->disconnect();
}

sub event_privmsg {
    my ($server, $data, $nick, $address) = @_;
    my ($target, $text) = split(/ :/, $data, 2);
    return if $target !~ $CHANNEL;

    try {
        return if $text !~ /\?(((\w+)\,)*((\w+) ))(\s*select.+)$/i;
        my @users = split(/\,/, $1);
        my $command = $+;

        $server->command("MSG ${target} [Loading] ${command}");

        my $irssi_callback = sub {
            my ($message) = @_;
            $server->command("MSG ${target} ${message}");
            Time::HiRes::sleep($FLOOD_DELAY);
        };
        main(\@users, $command, $irssi_callback);
    }catch {
        $server->command("MSG ${target} [Fail]");
        # TODO: error message
    }
}

Irssi::signal_add("event privmsg", "event_privmsg");
