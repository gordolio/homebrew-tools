class RrdtoolDev < Formula
  desc "Round Robin Database - with dev headers"
  homepage "https://oss.oetiker.ch/rrdtool/index.en.html"
  url "https://github.com/oetiker/rrdtool-1.x/releases/download/v1.7.2/rrdtool-1.7.2.tar.gz"
  sha256 "a199faeb7eff7cafc46fac253e682d833d08932f3db93a550a4a5af180ca58db"

  bottle do
    cellar :any
    rebuild 1
    sha256 "1059ba04ca08cf52d7eb4d4327e0d531d751ab8e43f78daa9a4141f78f7264ae" => :mojave
    sha256 "5ef3f96dffc6ff002feea4d89eadf80a16f9d39f86ec2096600fbbeb229f9c0d" => :high_sierra
    sha256 "d83b25d91e82350f92041e001fa0652c05198df9490323f6c9582028fde4ea5b" => :sierra
  end

  head do
    url "https://github.com/oetiker/rrdtool-1.x.git"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkg-config" => :build
  depends_on "glib"
  depends_on "pango"
  depends_on "perl"

  def install
    # fatal error: 'ruby/config.h' file not found
    ENV.delete("SDKROOT")

    args = %W[
      --disable-dependency-tracking
      --prefix=#{prefix}
      --disable-tcl
      --with-tcllib=/usr/lib
      --with-perl-options='PREFIX=#{prefix}'
      --disable-ruby-site-install
    ]

    inreplace "configure", /^sleep 1$/, "#sleep 1"

    system "./bootstrap" if build.head?
    system "./configure", *args

    # Needed to build proper Ruby bundle
    ENV["ARCHFLAGS"] = "-arch #{MacOS.preferred_arch}"

    system "make", "CC=#{ENV.cc}", "CXX=#{ENV.cxx}", "install"
    prefix.install "bindings/ruby/test.rb"
  end

  test do
    system "#{bin}/rrdtool", "create", "temperature.rrd", "--step", "300",
      "DS:temp:GAUGE:600:-273:5000", "RRA:AVERAGE:0.5:1:1200",
      "RRA:MIN:0.5:12:2400", "RRA:MAX:0.5:12:2400", "RRA:AVERAGE:0.5:12:2400"
    system "#{bin}/rrdtool", "dump", "temperature.rrd"
  end
end
