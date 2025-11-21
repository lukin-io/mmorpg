# frozen_string_literal: true

# Purpose:
#   Ensure Zeitwerk autoloaders are aware of custom application directories
#   (`app/components`, `app/lib`) without mutating Rails' frozen
#   `autoload_paths`/`eager_load_paths` arrays.
# Usage:
#   Runs automatically during Rails boot; no manual invocation required.
#   Classes/modules placed under these directories become autoloadable and
#   eager loaded in all environments.
# Returns:
#   Nothing. Side-effect: registered directories on each Zeitwerk loader.

Rails.autoloaders.each do |loader|
  %w[app/lib].each do |relative_path|
    full_path = Rails.root.join(relative_path)
    loader.push_dir(full_path) unless loader.dirs.include?(full_path.to_s)
  end
end
