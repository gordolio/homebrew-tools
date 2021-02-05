# typed: false
# frozen_string_literal: true

class V8AT59 < Formula
  desc "Google's open source JavaScript engine"
  homepage "https://github.com/v8/v8/wiki"
  url "https://github.com/v8/v8/archive/5.9.211.38.tar.gz"
  sha256 "2600828269b234cf34d3572ab7d6e61d5e3c4d77d67cc4174973b79a6e8d6388"

  keg_only :versioned_formula

  depends_on "ninja" => :build

  depends_on xcode: ["10.0", :build]

  # THESE ARE ACCURATE

  resource "v8/build" do
    url "https://chromium.googlesource.com/chromium/src/build.git",
        revision: "94c06fe70f3f6429c59e3ec0f6acd4f6710050b2"
  end

  resource "v8/third_party/jinja2" do
    url "https://chromium.googlesource.com/chromium/src/third_party/jinja2.git",
        revision: "d34383206fa42d52faa10bb9931d6d538f3a57e0"
  end

  resource "v8/third_party/markupsafe" do
    url "https://chromium.googlesource.com/chromium/src/third_party/markupsafe.git",
        revision: "8f45f5cfa0009d2a70589bcda0349b8cb2b72783"
  end

  resource "v8/base/trace_event/common" do
    url "https://chromium.googlesource.com/chromium/src/base/trace_event/common.git",
        revision: "06294c8a4a6f744ef284cd63cfe54dbf61eea290"
  end

  # resource "v8/third_party/googletest/src" do
  #  url "https://chromium.googlesource.com/external/github.com/google/googletest.git",
  #    :revision => "306f3754a71d6d1ac644681d3544d06744914228"
  # end

  resource "v8/third_party/icu" do
    url "https://chromium.googlesource.com/chromium/deps/icu.git",
        revision: "450be73c9ee8ae29d43d4fdc82febb2a5f62bfb5"
  end

  resource "v8/third_party/instrumented_libraries" do
    url "https://chromium.googlesource.com/chromium/src/third_party/instrumented_libraries.git",
        revision: "05d5695a73e78b9cae55b8579fd8bf22b85eb283"
  end

  resource "v8/tools/gyp" do
    url "https://chromium.googlesource.com/external/gyp.git",
        revision: "e7079f0e0e14108ab0dba58728ff219637458563"
  end

  resource "v8/tools/clang" do
    url "https://chromium.googlesource.com/chromium/src/tools/clang.git",
        revision: "49df471350a60efaec6951f321dd65475496ba17"
  end

  resource "v8/buildtools" do
    url "https://chromium.googlesource.com/chromium/buildtools.git",
        revision: "d3074448541662f242bcee623049c13a231b5648"
  end

  resource "v8/testing/gtest" do
    url "https://chromium.googlesource.com/external/github.com/google/googletest.git",
        revision: "6f8a66431cb592dad629028a50b3dd418a408c87"
  end

  resource "v8/testing/gmock" do
    url "https://chromium.googlesource.com/external/googlemock.git",
        revsion: "0421b6f358139f02e102c9c332ce19a33faf75be"
  end

  # END
  #
  #

  # maybe need this tool
  # resource "gn" do
  #  url "https://gn.googlesource.com/gn.git",
  #    :revision => "97cc440d84f050f99ff0161f9414bfa2ffa38f65"
  # end

  # resource "v8/third_party/zlib" do
  #  url "https://chromium.googlesource.com/chromium/src/third_party/zlib.git",
  #    :revision => "b9b9a5af7cca2e683e5f2aead8418e5bf9d5a7d5"
  # end

  def install
    (buildpath/"build").install resource("v8/build")
    (buildpath/"third_party/jinja2").install resource("v8/third_party/jinja2")
    (buildpath/"third_party/markupsafe").install resource("v8/third_party/markupsafe")
    # (buildpath/"third_party/googletest/src").install resource("v8/third_party/googletest/src")
    (buildpath/"base/trace_event/common").install resource("v8/base/trace_event/common")
    (buildpath/"third_party/icu").install resource("v8/third_party/icu")
    (buildpath/"third_party/instrumented_libraries").install resource("v8/third_party/instrumented_libraries")
    (buildpath/"buildtools").install resource("v8/buildtools")
    (buildpath/"tools/clang").install resource("v8/tools/clang")
    (buildpath/"testing/gtest").install resource("v8/testing/gtest")
    (buildpath/"testing/gmock").install resource("v8/testing/gmock")
    # (buildpath/"third_party/zlib").install resource("v8/third_party/zlib")

    # Bully GYP into correctly linking with c++11
    ENV.cxx11
    ENV["GYP_DEFINES"] = "clang=1 mac_deployment_target=#{MacOS.version}"
    (buildpath/"tools/gyp").install resource("v8/tools/gyp")

    # fix up libv8.dylib install_name
    # https://github.com/Homebrew/homebrew/issues/36571
    # https://code.google.com/p/v8/issues/detail?id=3871
    # inreplace "tools/gyp/v8.gyp",
    #          "'OTHER_LDFLAGS': ['-dynamiclib', '-all_load']",
    #          "\\0, 'DYLIB_INSTALL_NAME_BASE': '#{opt_lib}'"
    inreplace "src/v8.gyp",
              "'OTHER_LDFLAGS': ['-dynamiclib', '-all_load']",
              "\\0, 'DYLIB_INSTALL_NAME_BASE': '#{opt_lib}'"

    system "make", "native",
           "-j#{ENV.make_jobs}",
           "snapshot=on",
           "console=readline",
           "library=shared"

    prefix.install "include"
    cd "out/native" do
      lib.install Dir["lib*"]
      bin.install "d8", "lineprocessor", "mksnapshot", "preparser", "process", "shell" => "v8"
    end
  end

  test do
    assert_equal "Hello World!", pipe_output("#{bin}/v8 -e 'print(\"Hello World!\")'").chomp
  end
end
