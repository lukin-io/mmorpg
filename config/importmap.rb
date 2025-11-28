# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/actioncable", to: "actioncable.esm.js"
# Explicitly pin channels entry point and all channel files
pin "channels", to: "channels/index.js"
pin "channels/consumer", to: "channels/consumer.js"
pin "channels/presence_channel", to: "channels/presence_channel.js"
