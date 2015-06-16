name 'chef_eye'
maintainer 'Nikolay Murga'
maintainer_email 'nikolay.m@randrmusic.com'
license 'Apache v2.0'
description 'Installs/Configures chef_eye'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.0.2'

recipe 'chef_eye',  'Installs all'

supports 'ubuntu'
supports 'debian'

depends 'apt'
depends 'build-essential'
