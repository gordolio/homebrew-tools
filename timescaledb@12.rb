class TimescaledbAT12 < Formula
  desc "An open-source time-series database optimized for fast ingest and complex queries. Fully compatible with PostgreSQL."
  homepage "https://www.timescaledb.com"
  url "https://github.com/timescale/timescaledb/archive/refs/tags/2.5.1.tar.gz"
  sha256 "58a34a7a3a571339a019c0ae999b4ebb9f93e1e0cb828501e32bb073e0a25eac"
  version "2.5.1"
  env :std

  depends_on "cmake" => :build
  depends_on "postgresql@12" => :build
  depends_on "openssl" => :build
  depends_on "xz" => :build
  depends_on "timescaledb-tools" => :recommended

  option "with-oss-only", "Build TimescaleDB with only Apache-2 licensed code"

  def install
    ossvar = ""
    if build.with?("oss-only")
      ossvar = " -DAPACHE_ONLY=1"
    end
    ssldir = `#{(HOMEBREW_PREFIX/"bin"/"brew")} --prefix openssl`.chomp()
    postgresql_path = `#{(HOMEBREW_PREFIX/"bin"/"brew")} --prefix postgresql@12`.chomp()
    system "/bin/bash ./bootstrap " +
      "-DPG_CONFIG=#{postgresql_path}/bin/pg_config " +
      "-DREGRESS_CHECKS=OFF " +
      "-DOPENSSL_ROOT_DIR=\"#{ssldir}\" " +
      "-DCMAKE_BUILD_TYPE=Release " +
      "-DPG_INCLUDEDIR_SERVER=#{postgresql_path}/include/postgresql/server " +
      "-DPROJECT_INSTALL_METHOD=\"brew\"#{ossvar} " +
      "-DLINTER=OFF " +
      #"-DTAP_CHECKS=OFF " +
      #"-DWARNINGS_AS_ERRORS=OFF " +
      ""
    system "make -C build"
    system "make -C build install DESTDIR=#{buildpath}/stage"
    libdir = `#{postgresql_path}/bin/pg_config --pkglibdir`.chomp()
    sharedir = `#{postgresql_path}/bin/pg_config --sharedir`.chomp()
    `touch timescaledb_move.sh`
    `chmod +x timescaledb_move.sh`
    `echo "#!/bin/bash" >> timescaledb_move.sh`
    `echo "echo 'Moving files into place...'" >> timescaledb_move.sh`
    `echo "/usr/bin/install -c -m 755 \\\$(find #{lib} -name timescaledb*.so) #{libdir}/" >> timescaledb_move.sh`
    `echo "/usr/bin/install -c -m 644 #{share}/timescaledb/* #{sharedir}/extension/" >> timescaledb_move.sh`
    `echo "echo 'Success.'" >> timescaledb_move.sh`
    bin.install "timescaledb_move.sh"
    (lib/"timescaledb").install Dir["stage/**/lib/*"]
    (share/"timescaledb").install Dir["stage/**/share/postgresql*/extension/*"]
  end

  test do
    system "test", "-e", "#{lib}/timescaledb/timescaledb.so"
  end

  def caveats
    brew_cmd = (HOMEBREW_PREFIX/"bin"/"brew").to_s
    brew_dir = `#{brew_cmd} --prefix`.chomp()
    pg_var_dir = (HOMEBREW_PREFIX/"var"/"postgresql@12").to_s
    pgvar = `find #{pg_var_dir} -name "postgresql.conf" | head -n 1`.chomp()
    s = "RECOMMENDED: Run 'timescaledb-tune' to update your config settings for TimescaleDB.\n\n"
    s += "  timescaledb-tune --quiet --yes\n\n"

    s += "IF NOT, you'll need to make sure to update #{pgvar}\nto include the extension:\n\n"
    s += "  shared_preload_libraries = 'timescaledb'\n\n"

    s += "To finish the installation, you will need to run:\n\n"
    s += "  #{(bin/"timescaledb_move.sh")}\n\n"

    s += "If PostgreSQL is installed via Homebrew, restart it:\n\n"
    s += "  brew services restart postgresql@12\n\n"
    s
  end
end


