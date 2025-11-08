class Curl < Formula
  desc "Get a file from an HTTP, HTTPS or FTP server with HTTP/3 support using quiche"
  homepage "https://curl.se"
  url "https://curl.se/download/curl-8.17.0.tar.bz2"
  mirror "https://github.com/curl/curl/releases/download/curl-8_17_0/curl-8.17.0.tar.bz2"
  mirror "http://fresh-center.net/linux/www/curl-8.17.0.tar.bz2"
  mirror "http://fresh-center.net/linux/www/legacy/curl-8.17.0.tar.bz2"
  sha256 "230032528ce5f85594d4f3eace63364c4244ccc3c801b7f8db1982722f2761f4"
  license "curl"

  livecheck do
    url "https://curl.se/download/"
    regex(/href=.*?curl[._-]v?(.*?)\.t/i)
  end

  bottle do
    root_url "https://github.com/otsge/homebrew-stash2/releases/download/curl-8.17.0"
    sha256 cellar: :any, arm64_tahoe:   "91890e0da4de4cb709146b8869f02a92cdf3ad0c18a09e39a63bb2f9660f40a0"
    sha256 cellar: :any, arm64_sequoia: "3d40a0530458f9d2feb78afd9739e9e9bac766c15bb0536e6af7e633e534dc50"
    sha256 cellar: :any, arm64_sonoma:  "c6d0f6f72d16d5b7ef535fe1c4c14099707fd7ce05115cfdd50ad47f18691a1b"
    sha256 cellar: :any, sequoia:       "252c7c87073e3908cadbdd393fd188a5f3693f9814f155fcdb447d798d25c3d1"
  end

  head do
    url "https://github.com/curl/curl.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build

    resource "quiche" do
      url "https://github.com/cloudflare/quiche.git", branch: "master"
    end
  end

  keg_only :provided_by_macos

  depends_on "cmake" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "brotli"
  depends_on "libnghttp2"
  depends_on "libssh2"
  depends_on :macos
  depends_on "rtmpdump"
  depends_on "zstd"

  uses_from_macos "krb5"
  uses_from_macos "openldap"
  uses_from_macos "zlib"

  on_macos do
    depends_on "rust" => :build
  end

  on_monterey :or_older do
    depends_on "libidn2"
  end

  resource "quiche" do
    url "https://github.com/cloudflare/quiche.git",
    tag:      "0.24.6",
    revision: "020a43a0a5eed76f57dd3ce5012149aa576c594d"
    mirror "http://www.surge.box.ca/files/quiche-0.24.6.tar.bz2"
    sha256 "a5161fb0488a23ec2e31f85662ea8fb81875bea2358a3c26e2442e1605b72635"
  end

  def install
    tag_name = "curl-#{version.to_s.tr(".", "_")}"
    if build.stable? && stable.mirrors.grep(%r{\Ahttps?://(www\.)?github\.com/}).first.exclude?(tag_name)
      odie "Tag name #{tag_name} is not found in the GitHub mirror URL! " \
           "Please make sure the URL is correct."
    end

    # Use our `curl` formula with `wcurl`
    inreplace "scripts/wcurl", 'CMD="curl "', "CMD=\"#{opt_bin}/curl \""

    # Build with quiche:
    #  https://github.com/curl/curl/blob/master/docs/HTTP3.md#quiche-version
    quiche = buildpath/"quiche/quiche"
    boring = buildpath/"quiche/quiche/deps/boringssl"
    quiche_pc_path = buildpath/"quiche/target/release/quiche.pc"
    resource("quiche").stage quiche.parent
    cd "quiche" do
      ENV["CARGO_C_LIBDIR"] = lib.to_s

      ln_sf boring/"src", buildpath/"boringssl"

      # Build static libs only
      inreplace quiche/"Cargo.toml", /^crate-type = .*/, "crate-type = [\"staticlib\"]"
      inreplace quiche/"Cargo.toml", /^cmake = "0.1"/, "cmake = \"0.1.45\""
      inreplace "./Cargo.toml", /^debug = true/, "debug = false"

      system "cargo", "build", "--lib", "--package", "quiche", "--features", "ffi,pkg-config-meta,qlog", "--release"
      (buildpath/"boringssl/lib").install Pathname.glob("target/release/build/*/out/build/lib{crypto,ssl}.a")
      lib.install quiche.parent/"target/release/libquiche.a"
      include.install quiche/"include/quiche.h"
      inreplace quiche_pc_path do |s|
        s.gsub!(/includedir=.+/, "includedir=#{include}")
        s.gsub!(/libdir=.+/, "libdir=#{lib}")
      end
      (lib/"pkgconfig").install quiche_pc_path
    end

    ENV.append "LDFLAGS", "-Wl,-rpath,#{lib}/pkgconfig"

    if build.head?
      ENV.append_to_cflags "-march=native -O3 -pipe -flto=auto"

      system "autoreconf", "--force", "--install", "--verbose"
    end

    args = %W[
      --disable-silent-rules
      --with-openssl=#{buildpath}/boringssl
      --without-ca-bundle
      --without-ca-path
      --with-ca-fallback
      --with-default-ssl-backend=openssl
      --with-apple-sectrust
      --with-gssapi
      --with-librtmp
      --with-libssh2
      --with-quiche=#{lib}/pkgconfig
      --without-libpsl
      --with-zsh-functions-dir=#{zsh_completion}
      --with-fish-functions-dir=#{fish_completion}
      --enable-alt-svc
      --enable-ech
    ]

    args += if MacOS.version >= :ventura
      %w[
        --with-apple-idn
        --without-libidn2
      ]
    else
      %w[
        --without-apple-idn
        --with-libidn2
      ]
    end

    system "./configure", "LDFLAGS=#{ENV.ldflags}", *args, *std_configure_args
    system "make", "install"
    system "make", "install", "-C", "scripts"
    libexec.install "scripts/mk-ca-bundle.pl"
  end

  test do
    # Fetch the curl tarball and see that the checksum matches.
    # This requires a network connection, but so does Homebrew in general.
    filename = testpath/"test.tar.gz"
    system bin/"curl", "-L", stable.url, "-o", filename
    filename.verify_checksum stable.checksum

    # Check dependencies linked correctly
    curl_features = shell_output("#{bin}/curl-config --features").split("\n")
    %w[brotli GSS-API HTTP2 HTTP3 IDN libz SSL zstd].each do |feature|
      assert_includes curl_features, feature
    end
    curl_protocols = shell_output("#{bin}/curl-config --protocols").split("\n")
    %w[LDAPS RTMP SCP SFTP].each do |protocol|
      assert_includes curl_protocols, protocol
    end

    system libexec/"mk-ca-bundle.pl", "test.pem"
    assert_path_exists testpath/"test.pem"
    assert_path_exists testpath/"certdata.txt"

    with_env(PKG_CONFIG_PATH: lib/"pkgconfig") do
      system "pkgconf", "--cflags", "libcurl"
    end
  end
end
