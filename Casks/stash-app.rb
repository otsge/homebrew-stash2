cask "stash-app" do
  version "0.29.3"
  sha256 "a010afe8dfa87fedaa204211c1e48432700c37a3d2e87c81a1b5e80777012898"

  url "https://github.com/stashapp/stash/releases/download/v#{version}/Stash.app.zip",
      verified: "github.com/stashapp/stash/"
  name "Stash"
  desc "Organizer for your porn, written in Go"
  homepage "https://stashapp.cc/"

  app "Stash.app"

  # zap trash: [
  # ]
end
