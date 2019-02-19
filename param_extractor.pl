#!/usr/bin/perl
use Text::CSV;
use List::MoreUtils qw(uniq);
use JSON;
use Getopt::Std;
use strict;

my %OPTS;
getopts('hm:c:o:', \%OPTS);

my $MIME_TYPE = $OPTS{m};
my $LOGGER_2PLUS_CSV = $OPTS{c};
my $OUTPUT = $OPTS{o};

help() && exit if defined $OPTS{h};

my %FIELDS = (
    Number => 0,                Complete => 1,      Tool => 2,
    Host => 3,                  Method => 4,        Path => 5,
    Query => 6,                 Params => 7,        Status => 8,
    ResponseLength => 9,        MimeType => 10,     UrlExtension => 11,
    Comment => 12,              IsSSL => 13,        NewCookies => 14,
    RequestTime => 15,          ResponseTime => 16, ResponseDelay => 17, 
    ListenerInterface => 18,    Regex1Req => 19,    Regex1Resp => 20,
    Request => 21,              Response => 22
);


my $csv = Text::CSV->new({binary => 1});
my @PARAMS;

open(my $fhr, '<', $LOGGER_2PLUS_CSV);
while(my $row = $csv->getline($fhr)) {
    next unless ($row->[$FIELDS{MimeType}] eq $MIME_TYPE);

    my ($headersReq, $bodyReq) = split("\n\n",$row->[$row->[$FIELDS{Request}]]);
    my $paramsFromRequest = extract_json_params($bodyReq);
    my $paramsFromUrl = extract_url_params()
    
    my ($headersResp, $bodyResp) = split("\n\n",$row->[$row->[$FIELDS{Response}]]);
    my $paramsFromResponse = extract_json_params($bodyResp);

    push @PARAMS, @$paramsFromRequest, @$paramsFromUrl, @$paramsFromResponse; 
}
close $fhr;

open(my $fhw, '>', $OUTPUT);
my @uniqValues = uniq @PARAMS;
print join("\n",@uniqValues);
close $fwh;

sub extract_params_request {
    my $req = shift;
    my ($headers, $body) = split("\n\n",$req);

    my $json = decode_json $body;

    
}

sub extract_params_response {
    my $resp = shift;
    my ($headers, $body) = split("\n\n",$resp);

    my $json = decode_json $body;
}

sub extract_params {
    my $data = shift;
}

sub help {

}
