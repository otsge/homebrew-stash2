cask "stash-app" do
  version "0.29.1"
  sha256 "c2244a3caad8875c8c1c85bb05a30a490b0f679bce3586ae484d24bfdf95e148"

  url "https://github.com/stashapp/stash/releases/download/v#{version}/Stash.app.zip",
      verified: "github.com/stashapp/stash/"
  name "Stash"
  desc "Organizer for your porn, written in Go"
  homepage "https://stashapp.cc/"

  app "Stash.app"

  # zap trash: [
  # ]
end
