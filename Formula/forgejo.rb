class Forgejo < Formula
  desc "Self-hosted lightweight software forge"
  homepage "https://forgejo.org/"
  url "https://codeberg.org/forgejo/forgejo/releases/download/v13.0.2/forgejo-src-13.0.2.tar.gz"
  sha256 "6731d5e73a025c1a04aba0f84caf80886d5be0031f4c154ac63026e7fe30918a"
  license "GPL-3.0-or-later"
  head "https://codeberg.org/forgejo/forgejo.git", branch: "forgejo"

  bottle do
    root_url "https://github.com/otsge/homebrew-stash2/releases/download/forgejo-13.0.2"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "48078371485985e83c85c1eb5f7d5c382064a0885afc5fb853b1e8f38ef6c7e1"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "671e4804aed6642c5d1b6fcd734634d840a068818d56d5ece8e3f39955c94ee1"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "c12991d6bcfc89f8f43e4f0e0c09000b0c0bcc49112cfa11485a978db950bb76"
    sha256 cellar: :any_skip_relocation, sequoia:       "8798893a34076dcab65b9252a81ef3aa31a7b6adeac9f9baf577b5fa9c30d562"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "47e3c7c1bb97f20d74810a825a140a6da351c4ed7f08e6d4d0577c19e7ec74aa"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "52bd92631bc8729e3e092cf121e4aa5c487bae5e53c1a8e47526e17013702647"
  end

  depends_on "go" => :build
  depends_on "node" => :build

  uses_from_macos "sqlite"

  def install
    ENV["CGO_ENABLED"] = "1"
    ENV["TAGS"] = "bindata timetzdata sqlite sqlite_unlock_notify"
    system "make", "build"
    system "go", "build", "contrib/environment-to-ini/environment-to-ini.go"
    bin.install "gitea" => "forgejo"
    bin.install "environment-to-ini"
  end

  service do
    run [opt_bin/"forgejo", "web", "--work-path", var/"forgejo"]
    keep_alive true
    log_path var/"log/forgejo.log"
    error_log_path var/"log/forgejo.log"
  end

  test do
    ENV["FORGEJO_WORK_DIR"] = testpath
    port = free_port

    pid = fork do
      exec bin/"forgejo", "web", "--port", port.to_s, "--install-port", port.to_s
    end
    sleep 5
    sleep 10 if OS.mac? && Hardware::CPU.intel?

    output = shell_output("curl -s http://localhost:#{port}/api/settings/api")
    assert_match "Go to default page", output

    output = shell_output("curl -s http://localhost:#{port}/")
    assert_match "Installation - Forgejo: Beyond coding. We Forge.", output

    assert_match version.to_s, shell_output("#{bin}/forgejo -v")
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
