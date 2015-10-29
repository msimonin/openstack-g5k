def translate_vlan(nodes, jobname = "-1")
  if (jobname == "-1")
    return nodes
  end

  # get vlan number using the jobname variable
  vlan = $myxp.job_with_name("#{XP5K::Config[:jobname]}")['resources_by_type']['vlans'].first

  to_translate = nodes
  if !nodes.respond_to?('each')
    to_translate = [nodes]
  end
  to_translate.map {|node|
    a = node.split('.')
    a[0] = a[0]+"-kavlan-#{vlan}"
    a.join('.')
  }
end
