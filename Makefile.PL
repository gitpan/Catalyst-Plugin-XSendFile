use inc::Module::Install;
name 'Catalyst-Plugin-XSendFile';
all_from 'lib/Catalyst/Plugin/XSendFile.pm';

build_requires 'Test::More';

requires 'Catalyst'                 => '5.6902';
requires 'Catalyst::Utils'          => 0;
requires 'Class::Data::Inheritable' => 0;
requires 'File::Temp'               => 0;
requires 'File::stat'               => 0;
requires 'NEXT'                     => 0;
requires 'Path::Class'              => 0;
requires 'Scalar::Util'             => 0;
requires 'bytes'                    => 0;

use_test_base;
auto_include;
WriteAll;
