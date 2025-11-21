if defined?(User)
  admin = User.find_or_create_by!(email: "admin@neverlands.test") do |user|
    user.password = "ChangeMe123!"
    user.confirmed_at = Time.current
  end
  admin.add_role(:admin)
end

if defined?(Role)
  %i[player moderator gm admin].each do |role_name|
    Role.find_or_create_by!(name: role_name)
  end
end

if defined?(Flipper)
  %i[combat_system guilds housing].each do |feature|
    Flipper.add(feature)
  end
end
