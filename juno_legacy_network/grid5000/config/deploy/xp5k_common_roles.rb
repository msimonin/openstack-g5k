# define default roles here (on role per / xp5k job or xp5k role )

=begin
$myxp.roles.each do |role|
  role role.name.to_sym do
    $myxp.get_deployed_nodes(role.name) || role.servers
  end
end

@myxp.jobs.each do |job|
  role job["name"].to_sym do
    @myxp.get_deployed_nodes(job["name"]) || job["assigned_nodes"]
   end
end
=end

role :frontend do
    "#{XP5K::Config[:site]}"
end

role :subnet do
    "#{XP5K::Config[:site]}"
end
