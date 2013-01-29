use DBI qw(:sql_types);
use HTTP::Request;
use LWP::UserAgent;

my $dbh = DBI->connect(
    "dbi:SQLite:dbname=:memory:", "", "",
    {
        RaiseError => 1,
        sqlite_unicode => 1,
    }
);

$dbh->do("CREATE TABLE sgm (
     number INTEGER
    ,name TEXT
    ,level INTEGER
    ,score INTEGER
    ,fullcombo INTEGER
    ,rank INTEGER
    ,delta INTEGER
)");

my $request = HTTP::Request->new(GET => 'http://saucer.isdev.kr/sgm/all-default');
my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/5.0');
my $response = $ua->request($request);
if ($response->is_success) {
    my $string = $response->decoded_content;
    print $string;
}
 
$dbh->disconnect();
