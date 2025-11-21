if defined?(User)
  admin = User.find_or_create_by!(email: "admin@neverlands.test") do |user|
    user.password = "ChangeMe123!"
  end
  admin.add_role(:admin)
end

if defined?(Flipper)
  %i[combat_system guilds housing].each do |feature|
    Flipper.add(feature)
  end
end
