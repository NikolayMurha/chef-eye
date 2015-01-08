if node['chef_eye']['install_ruby']
 package 'ruby'
 package 'ruby-dev'
end

gem_package 'eye' do
 version node['chef_eye']['version']
end
