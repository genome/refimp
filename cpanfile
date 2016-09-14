requires 'perl', 'v5.10.1';

requires 'Bio::Seq';
requires 'Bio::SeqIO';
requires 'File::Slurp';
requires 'FindBin';
requires 'JSON';
requires 'MIME::Lite';
requires 'Params::Validate';
requires 'WWW::Mechanize';
requires 'YAML';
requires 'UR', '0.44', git => 'https://github.com/genome/UR.git';

on 'test' => sub {
    requires 'Devel::Cover';
    requires 'Test::More';
    requires 'Test::Exception';
    requires 'Test::MockObject';
};

