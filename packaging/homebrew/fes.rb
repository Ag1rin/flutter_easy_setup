class Fes < Formula
  desc "Install and repair Flutter on Windows, macOS, and Linux"
  homepage "https://github.com/Ag1rin/flutter_easy_setup"
  version "1.1.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/Ag1rin/flutter_easy_setup/releases/download/v1.1.0/fes-macos-arm64"
      sha256 "2398413841802055212b59699c0c65410d2c71d0bc4fd5aa64fd9d837ac70015"
    end
    on_intel do
      url "https://github.com/Ag1rin/flutter_easy_setup/releases/download/v1.1.0/fes-macos-x64"
      sha256 "1464cd5b918ad55223310f4457fec942ceecf3d41d33490c3b9d4563a3d775c0"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/Ag1rin/flutter_easy_setup/releases/download/v1.1.0/fes-linux-x64"
      sha256 "8e8ee4791f9e09accc1971d97d6b34f5b0e0f6f0c68fdcb283519596ca6fea2e"
    end
    on_arm do
      url "https://github.com/Ag1rin/flutter_easy_setup/releases/download/v1.1.0/fes-linux-arm64"
      sha256 "24603796af9d49a882d0114b1110b93f676196648270d4cac8afb4582b00cda9"
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
