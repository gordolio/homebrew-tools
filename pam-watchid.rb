# typed: false
# frozen_string_literal: true

class PamWatchid < Formula
  desc "PAM plugin module that allows the Apple Watch to be used for authentication"
  homepage "https://github.com/gordolio/pam-watchid"
  head "https://github.com/gordolio/pam-watchid.git"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  def caveats
    <<~EOS
      Make sure you add the module to your targeted service in /etc/pam.d/:
        auth  sufficient  pam_watchid.so
        ...
      See https://github.com/gordolio/pam-watchid
    EOS
  end
end
