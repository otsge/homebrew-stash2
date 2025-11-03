class Rclone < Formula
  desc "Rsync for cloud storage"
  homepage "https://rclone.org/"
  url "https://github.com/rclone/rclone/archive/refs/tags/v1.71.2.tar.gz"
  sha256 "54c619a2f6921981f276f01a12209bf2f2b5d94f580cd8699e93aa7c3e9ee9ba"
  license "MIT"
  head "https://github.com/rclone/rclone.git", branch: "master"

  bottle do
    root_url "https://github.com/otsge/homebrew-stash2/releases/download/rclone-1.71.2"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "a99757cb957f3559356d2fd690397731bd2bd7de82686cc83eed2604aa338272"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "d9bce0a8c3a186555bd5be4c9017b6a82fae3ddad2c70c371f0e32899f89bf9e"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "0e751db557a91cf9ac6262e98e6205b5237dc994328f548fa73ac3026c6feb85"
    sha256 cellar: :any_skip_relocation, sequoia:       "b498476e39cfa07abf28b5936287259c75ff8b0d7282514f5188ddc298d0d74b"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "8810ed2ee61f0992db002312a90532d0dadd64c0bbb98873163666b8f49c9c20"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "c91488fcd4f927438a85b816bfffd4b8ae79f1d7c8b3b652c2f866e6f66b71de"
  end

  depends_on "go" => :build

  on_linux do
    depends_on "libfuse@2"
  end

  def install
    ENV["GOPATH"] = prefix.to_s
    ENV["GOBIN"] = bin.to_s
    ENV["GOMODCACHE"] = "#{HOMEBREW_CACHE}/go_mod_cache/pkg/mod"
    ENV["CGO_FLAGS"] = "-g -O3"
    args = ["GOTAGS=cmount"]
    system "make", *args
    man1.install "rclone.1"
    system bin/"rclone", "genautocomplete", "bash", "rclone.bash"
    system bin/"rclone", "genautocomplete", "zsh", "_rclone"
    system bin/"rclone", "genautocomplete", "fish", "rclone.fish"
    bash_completion.install "rclone.bash" => "rclone"
    zsh_completion.install "_rclone"
    fish_completion.install "rclone.fish"
  end

  test do
    (testpath/"file1.txt").write "Test!"
    system bin/"rclone", "copy", testpath/"file1.txt", testpath/"dist"
    assert_match File.read(testpath/"file1.txt"), File.read(testpath/"dist/file1.txt")
  end
end
