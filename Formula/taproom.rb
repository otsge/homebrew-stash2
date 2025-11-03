class Taproom < Formula
  desc "Interactive TUI for Homebrew"
  homepage "https://github.com/hzqtc/taproom"
  url "https://github.com/hzqtc/taproom/archive/refs/tags/v0.4.5.tar.gz"
  sha256 "311a7a3fb39cfbf478bd0a9ac2c6b5cc5fc509383edad223b119ec89f7ef66b5"
  license "MIT"
  head "https://github.com/hzqtc/taproom.git", branch: "main"

  bottle do
    root_url "https://github.com/otsge/homebrew-stash2/releases/download/taproom-0.4.5"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "92be31aa016cec8d16bfc5072e645a80f2999c5286bd8e730d38edd333e534e3"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "453ed7ed0c49a70c71237ae5d1eede5efc86ca565967970cc0db546da15dbd77"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "cd07acd578368e3457a40c9308db5bb70aec5b97519b74b2e1dcb36ea2e841b6"
    sha256 cellar: :any_skip_relocation, sequoia:       "6c334f513507a23dd0286483e98f989c61baf3979b4cf6ea9e535d20d1dcddd0"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "e8c3b7408a4f55cd4531864630d93c3cc78325fb68d3b8ff4084d7e32384b3d0"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "ab242bc034f9a7d49dbe807999673b93e92b0ff9ea7185711fde6367f15037f3"
  end

  depends_on "go" => :build

  def install
    system "go", "build", "-trimpath", *std_go_args(ldflags: "-s -w")
  end

  test do
    require "pty"
    require "expect"
    require "io/console"
    timeout = 30

    PTY.spawn("#{bin}/taproom --hide-columns Size") do |r, w, pid|
      r.winsize = [80, 130]
      begin
        refute_nil r.expect("Loading all Casks", timeout), "Expected cask loading message"
        w.write "q"
        r.read
      rescue Errno::EIO
        # GNU/Linux raises EIO when read is done on closed pty
      ensure
        r.close
        w.close
        Process.wait(pid)
      end
    end
  end
end
