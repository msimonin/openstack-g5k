# define your capistrano roles here.
#
# role :myrole do
#   role_myrole
# end
#
#

role :puppet_master do
  $myxp.get_deployed_nodes('puppet')
end

role :puppet_clients do
  $myxp.get_deployed_nodes('controller') +
  $myxp.get_deployed_nodes('network') + 
  $myxp.get_deployed_nodes('compute')
end

role :controller do
 $myxp.get_deployed_nodes('controller')
end

role :network do
  $myxp.get_deployed_nodes('network')
end

role :compute do
  $myxp.get_deployed_nodes('compute')
end

role :router do
  $myxp.get_deployed_nodes('router')
end

role :frontend do
  "#{XP5K::Config[:user]}@#{XP5K::Config[:site]}"
end

