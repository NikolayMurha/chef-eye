if node['eye']['install_ruby']
 package 'ruby'
 package 'ruby-dev'
end
gem_package 'eye'
