use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new(
    module_name => 'Catalyst::Plugin::XSendFile',
    license     => 'perl',
    requires    => {
        'Catalyst'                 => '5.6902',
        'Class::Data::Inheritable' => 0,
        'NEXT'                     => 0,
        'MIME::Types'              => 0,
        'Path::Class'              => 0,
    },
)->create_build_script;
