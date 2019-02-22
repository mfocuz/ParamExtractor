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

my $firstRow = $csv->getline($fhr);
my $i = 0;

foreach my $colName (@$firstRow) {
    die "Inappropriate columns $colName != $FIELDS{$i}" if ($FIELDS{$colName} != $i);
    $i++;
}

while(my $row = $csv->getline($fhr)) {
    my ($headersReq, $bodyReq) = split("\r\n\r\n",$row->[$FIELDS{Request}]);
    my $paramsFromUrl = extract_url_params($headersReq);
    push @PARAMS,@$paramsFromUrl;

    next unless ($row->[$FIELDS{MimeType}] eq $MIME_TYPE);
   
    if (length $bodyReq > 0) {
        my $paramsFromRequest = extract_json_params(decode_json $bodyReq);
        push @PARAMS, @$paramsFromRequest;
    }
    my ($headersResp, $bodyResp) = split("\r\n\r\n",$row->[$FIELDS{Response}]);
    print $bodyResp,"\n";
    if (length $bodyResp > 0) {
        my $paramsFromResponse = extract_json_params(decode_json($bodyResp));
        push @PARAMS, @$paramsFromResponse;
    }
}
close $fhr;

#open(my $fhw, '>', $OUTPUT);
#my @uniqValues = uniq @PARAMS;
#print join("\n",@uniqValues);
print join("\n",@PARAMS);
#close $fwh;

sub extract_json_params {
    my $data = shift;

    my @params;
    my $walk_json;
    $walk_json = sub {
        my $json = shift;

        if (ref $json eq 'HASH') {
            foreach my $key (keys %$json) {
                push @params,$key;
                $walk_json->($json->{$key});
            }
        } elsif (ref $json eq 'ARRAY') {
            foreach my $element (@$json) {
                $walk_json->($element);
            }
        } else {
            push @params, $json;
        }
    };
    $walk_json->($data);

    return \@params;
}

sub extract_url_params {
    my @headers = split("\r\n",shift);

    my ($method, $url, $httpVer) = $headers[0] =~ /(.*)\s(.*)\s(.*)/;
    my ($uri, $params) = $url =~ /(.*)\?(.*)/;

    return [] if !defined $params;
    
    my @params;
    foreach my $p (split("&",$params)) {
        my ($k,$v) = split('=',$p);
        push @params,$k;
    }
    return \@params;
}

sub help {

}
