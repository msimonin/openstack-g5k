# relative to the capfile
set :recipes_path, "./xpm_modules"

# Enable pretty output. Remove it if you want full logging
#logger.level = Logger::IMPORTANT
#STDOUT.sync

load "config/deploy/xp5k.rb"
load "config/lib/vlan.rb"

# load recipes of dependencies
recipes = Dir.glob("#{recipes_path}/*");
recipes.each do |recipe|
    load "#{recipe}/recipe.rb"
end

#override default roles
roles = Dir.glob("exports/*/roles.rb")
roles.each do |role|
    load "#{role}"
end

# load recipes
if File.exist?("recipe.rb")
  load "recipe.rb"
end


# load extra recipes.
extras = Dir.glob("recipes/*.rb")
extras.each do |extra|
  load "#{extra}"
end
