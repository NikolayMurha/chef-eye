
gem = chef_gem 'eye'
gem.run_action(:install)
node['eye']['applications'].each do |name, options|
  options = options.to_hash
  owner = options.delete('owner') || 'root'
  group = options.delete('group')
  cookbook = options.delete('cookbook') || 'chef_eye'
  chef_eye_application name do
    owner owner
    group group
    cookbook cookbook
    config options
    notifies  :reload, "service[eye_#{owner}]"
  end
end
