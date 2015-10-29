task :xp5k do
  puts "  XP5K launched (submission and deployment)"
end


desc 'Submit jobs'
task :submit do
  $myxp.submit
  $myxp.wait_for_jobs
end

desc 'Deploy with Kadeploy'
task :deploy  do
  $myxp.deploy
end

desc 'Remove all running jobs'
task :clean do
logger.debug "Clean all Grid'5000 running jobs..."
  $myxp.clean
end

desc 'Describe the cluster'
task :describe do
  servers = find_servers
  servers_by_roles = {}
  servers.each do |server|
    role_names = role_names_for_host(server)
    role_names.each do |role|
      servers_by_roles[role] ||= [] 
      servers_by_roles[role] << server
    end
  end 
  puts "+----------------------------------------------------------------------+"
  servers_by_roles.each do |role, servers|
    print "|"+"%-30s".blue % role
    server = servers.pop
    puts "%-40s|" % server
    servers.each do |server|
      print "|"+"%-30s" % " "
      puts "%-40s|" % server
    end 
    puts "+----------------------------------------------------------------------+"
  end
end

after "xp5k", "submit", "deploy"
