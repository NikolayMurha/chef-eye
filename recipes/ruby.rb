if node['chef_eye']['install_ruby']
  package 'ruby1.9.1'
  package 'ruby1.9.1-dev'
end

gem_package 'eye' do
  version node['chef_eye']['version']
end
