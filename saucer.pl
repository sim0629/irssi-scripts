use DBI qw(:sql_types);
use HTTP::Request;
use LWP::UserAgent;
use Mojo::DOM;

sub fetch {
    my ($dbh, $user) = @_;

    my $safe_user = $dbh->quote_identifier($user);

    $dbh->do("CREATE TABLE ${safe_user} (
         number INTEGER
        ,name TEXT
        ,level INTEGER
        ,score INTEGER
        ,fullcombo INTEGER
        ,rank INTEGER
        ,delta INTEGER
    )");

    my $sth = $dbh->prepare("INSERT INTO ${safe_user} (
         number
        ,name
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
                 $number
                ,$name
                ,$level
                ,$score
                ,$fullcombo
                ,$rank
                ,$delta
            );
        }
    }
}

sub execute {
    my ($dbh, $command) = @_;

    $select = $dbh->prepare($command);
    $select->execute();
    $select->bind_columns(\$result);
    while($select->fetch()) {
        print $result;
    }
}

sub main {
    my $user = 'sgm';
    my $command = 'select count(*) from sgm';

    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=:memory:", "", "",
        {
            RaiseError => 1,
            sqlite_unicode => 1,
        }
    );

    fetch($dbh, $user);
    execute($dbh, $command);

    $dbh->disconnect();
}

main;
