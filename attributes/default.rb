default['eye']['bin'] = '/usr/local/bin/eye'
default['eye']['services'] = ['root']

default['eye']['applications'] = {}


default['eye']['services'] = {
  root: {
    mail: {
      :host => "mx.some.host",
      :port => 25,
      :domain => "some.host"
    },
    contacts: {
      errors: [:mail, 'error@some.host'],
      dev: [:mail, 'dev@some.host']
    }
  }
}
