#!/usr/bin/env perl

use strict;
use warnings;

use TestEnv;

use File::Spec;
use Test::Exception;
use Test::More tests => 6;

my $pkg_name = 'RefImp::Role::PropertyValuesFromFile';
use_ok($pkg_name) or die;

class Person {
    has => {
        name => { is => 'Text', },
    },
};

class FromFileTest {
    is => 'Command::V2',
    has_optional => { happiness => { is => 'Text', }, },
    has_many_optional => {
        names => { is => 'Text', doc => '', },
        people => { is => 'Person', doc => '', },
        other => { is => 'Text', doc => '', },
    },
};
sub FromFileTest::execute {1}

subtest 'errors' => sub{
    plan tests => 3;

    throws_ok(
        sub{ RefImp::Role::PropertyValuesFromFile::class_properties_can_load_from_file('FromFileTest', 'blah'); },
        qr/No property meta for blah/,
        'class_properties_can_load_from_file fails with unknown property',
    );

    class ClassIsNotcommandV2 { is => 'UR::Object', has => { things => {}, }};
    throws_ok(
        sub{  RefImp::Role::PropertyValuesFromFile::class_properties_can_load_from_file('ClassIsNotcommandV2', 'things'); },
        qr/It is not a 'Command::V2'/,
        'fails when class is not Command::V2',
    );

    throws_ok(
        sub{  RefImp::Role::PropertyValuesFromFile::class_properties_can_load_from_file('FromFileTest', 'happiness'); },
        qr/is not is_many/,
        'fails when property is not is_many',
    );
};

subtest 'class_properties_can_load_from_file' => sub{
    plan tests => 3;

    RefImp::Role::PropertyValuesFromFile::class_properties_can_load_from_file('FromFileTest', 'names');
    my $property = FromFileTest->__meta__->property_meta_for_name('names');
    ok($property->{can_load_from_file}, 'set can_load_from_file for names');
    like($property->{doc}, qr/Optionally, pass a single columned file to load values/, 'appended doc for names');

    $property = FromFileTest->__meta__->property_meta_for_name('other');
    ok(!$property->{can_load_from_file}, 'did not set can_load_from_file for other');

};

subtest 'execute with strings' => sub{
    plan tests => 4;

    my @names = (qw/ Luke Leia /);
    my @argv = ('--names', join(',', @names));
    my ($class, $params, $errors) = FromFileTest->resolve_class_and_params_for_argv(@argv);
    is($class, 'FromFileTest', 'resolve_class_and_params_for_argv class');
    is_deeply($params, { names => \@names },'resolve_class_and_params_for_argv params');
    ok(!$errors, 'resolve_class_and_params_for_argv no errors');

    my $cmd = $class->execute(%$params);
    ok($cmd->result, 'execute with params');

};

subtest 'execute with file' => sub{
    plan tests => 4;

    my $names_file = File::Spec->join(TestEnv::test_data_directory_for_package($pkg_name), 'names.txt');
    my @argv = ('--names', $names_file);
    my ($class, $params, $errors) = FromFileTest->resolve_class_and_params_for_argv(@argv);
    is($class, 'FromFileTest', 'resolve_class_and_params_for_argv class');
    is_deeply($params, { names => ['Han Solo', 'Chewbaca'] }, 'resolve_class_and_params_for_argv params');
    ok(!$errors, 'resolve_class_and_params_for_argv no errors');

    my $cmd = $class->execute(%$params);
    ok($cmd->result, 'execute with params');

};

subtest 'execute with file getting objects' => sub{
    plan tests => 4;

    RefImp::Role::PropertyValuesFromFile::class_properties_can_load_from_file('FromFileTest', 'people');

    my $names_file = File::Spec->join(TestEnv::test_data_directory_for_package($pkg_name), 'names.txt');
    my @people;
    push @people, Person->create(name => 'Han Solo');
    my @argv = ('--people', $names_file);
    my ($class, $params, $errors) = FromFileTest->resolve_class_and_params_for_argv(@argv);
    is($class, 'FromFileTest', 'resolve_class_and_params_for_argv class');
    is_deeply($params, { people => ['Han Solo', 'Chewbaca'] }, 'resolve_class_and_params_for_argv params');
    ok(!$errors, 'resolve_class_and_params_for_argv no errors');

    my $cmd = $class->execute(%$params);
    ok($cmd->result, 'execute with params');

};

done_testing();
