# We define the capistrano roles here
# They often map the xp5k roles


# The puppet master
role :puppet_master do
  $myxp.get_deployed_nodes('puppet')
end

# The other nodes are puppet clients
role :puppet_clients do
  $myxp.get_deployed_nodes('controller') +
  $myxp.get_deployed_nodes('network') + 
  $myxp.get_deployed_nodes('compute')
end

# We define the Openstack specific roles :
#   - The controller node
role :controller do
 $myxp.get_deployed_nodes('controller')
end

#   - The network role
role :network do
  $myxp.get_deployed_nodes('network')
end

#   - The compute role
role :compute do
  $myxp.get_deployed_nodes('compute')
end

#   - The frontend role
#   It is used to get some missing info on G5k API.
role :frontend do
  "#{XP5K::Config[:user]}@#{XP5K::Config[:site]}"
end

