if node['chef_eye']['install_ruby']
  package 'ruby1.9'
  package 'ruby1.9-dev'
end

gem_package 'eye' do
  version node['chef_eye']['version']
end
