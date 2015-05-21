default['chef_eye']['eye_bin'] = '/usr/local/bin/eye'
default['chef_eye']['plugins'] = {
#   'eye-hipchat' => {
#     version: '0.0.0',
#     require: 'eye/notify/hipchat',
#   },
#   'eye-bugsnag' => {
#     version: '0.0.0',
#     require: 'eye/notify/bugsnag',
#   },
#   'eye-http' => {
#     version: '0.0.0',
#     require: 'eye-http',
#   }
}

default['chef_eye']['leye_bin'] = '/usr/local/bin/leye'
default['chef_eye']['version'] = '0.6.4'
default['chef_eye']['install_ruby'] = true
default['chef_eye']['services'] = []
default['chef_eye']['service_type'] = 'upstart'
default['chef_eye']['applications'] = {}
