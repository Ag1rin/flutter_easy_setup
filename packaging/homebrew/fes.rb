class Fes < Formula
  desc "Install and repair Flutter on Windows, macOS, and Linux"
  homepage "https://github.com/Ag1rin/flutter_easy_setup"
  version "1.1.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/Ag1rin/flutter_easy_setup/releases/download/v1.1.0/fes-macos-arm64"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
    on_intel do
      url "https://github.com/Ag1rin/flutter_easy_setup/releases/download/v1.1.0/fes-macos-x64"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/Ag1rin/flutter_easy_setup/releases/download/v1.1.0/fes-linux-x64"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
    on_arm do
      url "https://github.com/Ag1rin/flutter_easy_setup/releases/download/v1.1.0/fes-linux-arm64"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end

  def install
    if OS.mac?
      bin.install OS.mac? && Hardware::CPU.arm? ? "fes-macos-arm64" : "fes-macos-x64" => "fes"
    else
      bin.install Hardware::CPU.arm? ? "fes-linux-arm64" : "fes-linux-x64" => "fes"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/fes --version")
  end
end
