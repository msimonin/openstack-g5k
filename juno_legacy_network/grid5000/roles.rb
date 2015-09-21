# define your capistrano roles here.
#
# role :myrole do
#   role_myrole
# end
#
#

role :puppet_master do
  translate_vlan($myxp.get_deployed_nodes('puppet'), XP5K::Config[:jobname])
end

role :puppet_clients do
  translate_vlan(
  $myxp.get_deployed_nodes('controller') +
  $myxp.get_deployed_nodes('compute'), XP5K::Config[:jobname])
end

role :controller do
  translate_vlan($myxp.get_deployed_nodes('controller'), XP5K::Config[:jobname])
end

role :compute do
  translate_vlan($myxp.get_deployed_nodes('compute'), XP5K::Config[:jobname])
end

role :frontend do
  "#{XP5K::Config[:user]}@#{XP5K::Config[:site]}"
end
