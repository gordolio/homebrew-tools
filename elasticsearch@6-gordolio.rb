class ElasticsearchAT6Gordolio < Formula
  desc "Distributed search & analytics engine"
  homepage "https://www.elastic.co/products/elasticsearch"
  url "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-6.8.13.tar.gz"
  sha256 "e3a41d1a58898c18e9f80d45b1bf9f413779bdda9621027a6fe87f3a0f59ec90"
  license "Apache-2.0"

  keg_only :versioned_formula

  depends_on "openjdk@8"

  def cluster_name
    "elasticsearch6_#{ENV["USER"]}"
  end

  def install
    if build.head?
      # Build the package from source
      system "gradle", "clean", ":distribution:tar:assemble"
      # Extract the package to the tar directory
      mkdir "tar"
      cd "tar"
      system "tar", "--strip-components=1", "-xf",
        Dir["../distribution/tar/build/distributions/elasticsearch-*.tar.gz"].first
    end

    # Remove Windows files
    rm_f Dir["bin/*.bat"]
    rm_f Dir["bin/*.exe"]

    # Install everything else into package directory
    libexec.install "bin", "config", "lib", "modules"

    inreplace libexec/"bin/elasticsearch-env",
              "if [ -z \"$ES_PATH_CONF\" ]; then ES_PATH_CONF=\"$ES_HOME\"/config; fi",
              "if [ -z \"$ES_PATH_CONF\" ]; then ES_PATH_CONF=\"#{etc}/elasticsearch6\"; fi"

    # Set up Elasticsearch for local development:
    inreplace "#{libexec}/config/elasticsearch.yml" do |s|
      # 1. Give the cluster a unique name
      s.gsub!(/#\s*cluster\.name: .*/, "cluster.name: #{cluster_name}")

      # 2. Configure paths
      s.sub!(%r{#\s*path\.data: /path/to.+$}, "path.data: #{var}/lib/elasticsearch6/")
      s.sub!(%r{#\s*path\.logs: /path/to.+$}, "path.logs: #{var}/log/elasticsearch6/")
    end

    # Move config files into etc
    (etc/"elasticsearch6").install Dir[libexec/"config/*"]
    (libexec/"config").rmtree

    Dir.foreach(libexec/"bin") do |f|
      next if f == "." || f == ".." || !File.extname(f).empty?

      new_link = f
      if new_link =~ /^elasticsearch(.*)/
        new_link = "elasticsearch6#{$1}"
      end
      symlink = Hash.new
      symlink[(libexec/"bin"/f)] = libexec/"bin"/new_link

      bin.install_symlink(symlink)

      dst = libexec/"bin"
      dst.install(libexec/"bin"/new_link)
      new_file = dst.join(new_link.basename)
      new_link.write_env_script(new_file, Language::Java.java_home_env("1.8"))
    end

  end

  def post_install
    # Make sure runtime directories exist
    (var/"lib/elasticsearch6").mkpath
    (var/"log/elasticsearch6").mkpath
    ln_s etc/"elasticsearch6", libexec/"config" unless (libexec/"config").exist?
    (var/"elasticsearch6/plugins").mkpath
    ln_s var/"elasticsearch6/plugins", libexec/"plugins" unless (libexec/"plugins").exist?
    # fix test not being able to create keystore because of sandbox permissions
    system bin/"elasticsearch6-keystore", "create" unless (etc/"elasticsearch6/elasticsearch.keystore").exist?
  end

  def caveats
    <<~EOS
      Data:    #{var}/lib/elasticsearch6/
      Logs:    #{var}/log/elasticsearch6/#{cluster_name}.log
      Plugins: #{var}/elasticsearch6/plugins/
      Config:  #{etc}/elasticsearch6/
    EOS
  end

  plist_options manual: "elasticsearch6"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>KeepAlive</key>
          <false/>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{opt_bin}/elasticsearch6</string>
          </array>
          <key>EnvironmentVariables</key>
          <dict>
          </dict>
          <key>RunAtLoad</key>
          <true/>
          <key>WorkingDirectory</key>
          <string>#{var}</string>
          <key>StandardErrorPath</key>
          <string>#{var}/log/elasticsearch6.log</string>
          <key>StandardOutPath</key>
          <string>#{var}/log/elasticsearch6.log</string>
        </dict>
      </plist>
    EOS
  end

  test do
    assert_includes(stable.url, "-oss-")

    port = free_port
    system "#{bin}/elasticsearch6-plugin", "list"
    pid = testpath/"pid"
    begin
      system "#{bin}/elasticsearch6", "-d", "-p", pid, "-Epath.data=#{testpath}/data", "-Ehttp.port=#{port}"
      sleep 10
      system "curl", "-XGET", "localhost:#{port}/"
    ensure
      Process.kill(9, pid.read.to_i)
    end

    port = free_port
    (testpath/"config/elasticsearch.yml").write <<~EOS
      path.data: #{testpath}/data
      path.logs: #{testpath}/logs
      node.name: test-es-path-conf
      http.port: #{port}
    EOS

    cp etc/"elasticsearch6/jvm.options", "config"
    cp etc/"elasticsearch6/log4j2.properties", "config"

    ENV["ES_PATH_CONF"] = testpath/"config"
    pid = testpath/"pid"
    begin
      system "#{bin}/elasticsearch6", "-d", "-p", pid
      sleep 10
      system "curl", "-XGET", "localhost:#{port}/"
      output = shell_output("curl -s -XGET localhost:#{port}/_cat/nodes")
      assert_match "test-es-path-conf", output
    ensure
      Process.kill(9, pid.read.to_i)
    end
  end
end
