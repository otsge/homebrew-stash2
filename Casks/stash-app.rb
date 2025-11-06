cask "stash-app" do
  version "0.29.2"
  sha256 "e4769b6921669a474e0e13ff1853e86721d049cd99be0906cc6c79f718a4e8f6"

  url "https://github.com/stashapp/stash/releases/download/v#{version}/Stash.app.zip",
      verified: "github.com/stashapp/stash/"
  name "Stash"
  desc "Organizer for your porn, written in Go"
  homepage "https://stashapp.cc/"

  app "Stash.app"

  # zap trash: [
  # ]
end
