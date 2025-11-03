class Aria2 < Formula
  desc "Download with resuming and segmented downloading"
  homepage "https://aria2.github.io/"
  url "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0.tar.xz"
  sha256 "60a420ad7085eb616cb6e2bdf0a7206d68ff3d37fb5a956dc44242eb2f79b66b"
  license "GPL-2.0-or-later"

  bottle do
    root_url "https://github.com/otsge/homebrew-stash2/releases/download/aria2-1.37.0"
    sha256 cellar: :any,                 arm64_tahoe:   "19757a4ee17014b0f9eeba27c8e272320579533157f47157686a8002785805af"
    sha256 cellar: :any,                 arm64_sequoia: "893dbcfddc6ea1dc6e80f2afb413f5f80d7e10514d40ef4ad53a8d2932438548"
    sha256 cellar: :any,                 arm64_sonoma:  "ac120c8be89a6d3c3878ddcdbf537ffd846f0a3aa1edbef53c8402e38c0aecfe"
    sha256 cellar: :any,                 sequoia:       "e06fed1a90699b2b7961e60b3ac3d0ade6a974ade1f8ac70cd9d510575799e56"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "5309c307f52ff19194d003d3dbafb85373f842aa3925889db6a49b91489272af"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "37fc9a924da38f6819eb07ee5cecabe82c2ba66ba98abebb0475895a3274d952"
  end

  head do
    url "https://github.com/aria2/aria2.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => :build

  depends_on "c-ares"
  depends_on "libssh2"
  depends_on "sqlite"

  uses_from_macos "libxml2"
  uses_from_macos "zlib"

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "openssl@3"
  end

  def install
    ENV.cxx11

    if build.head?
      ENV.append_to_cflags "-march=native -O3 -pipe -flto=auto"

      system "autoreconf", "--force", "--install", "--verbose"
    end

    args = %w[
      --disable-silent-rules
      --disable-nls
      --enable-metalink
      --enable-bittorrent
      --with-libcares
      --with-libssh2
      --with-libxml2
      --with-libz
      --without-gnutls
      --without-libgcrypt
      --without-libgmp
      --without-libnettle
    ]
    if OS.mac?
      args << "--with-appletls"
      args << "--without-openssl"
    else
      args << "--without-appletls"
      args << "--with-openssl"
    end

    system "./configure", *args, *std_configure_args
    system "make", "install"

    bash_completion.install "doc/bash_completion/aria2c"
  end

  test do
    system bin/"aria2c", "https://brew.sh/"
    assert_path_exists testpath/"index.html", "Failed to create index.html!"
  end
end
