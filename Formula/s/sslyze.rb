class Sslyze < Formula
  include Language::Python::Virtualenv

  desc "SSL scanner"
  homepage "https://github.com/nabla-c0d3/sslyze"
  license "AGPL-3.0-only"

  stable do
    url "https://files.pythonhosted.org/packages/1d/21/9a43c69b007a995d24ac29dcb4f17d8f70314900236a0be677298307f53d/sslyze-6.1.0.tar.gz"
    sha256 "61919db600167f5e593448220dd6137e9753f95d6c7511271975def7bdc286e0"

    resource "nassl" do
      url "https://github.com/nabla-c0d3/nassl/archive/refs/tags/5.3.0.tar.gz"
      sha256 "bf37081a8ff6781a9460e9d774474456081296707213a2ccecfa067376426646"
    end
  end

  bottle do
    sha256 cellar: :any,                 arm64_ventura:  "4b78c64baa9288800f6d3724d61680822215ac119c914fcfe88d0d07cb42e96b"
    sha256 cellar: :any,                 arm64_monterey: "2bce9a22e71eca7501b53978f4c790bfe0ea918bc769815fc39db0c913949766"
    sha256 cellar: :any,                 arm64_big_sur:  "e6db8bf038025808d83b3e44957fc1c7ae5b613b26f375181287c824c5409b35"
    sha256 cellar: :any,                 ventura:        "cfe2b486e6dc00fc6afa98f69eb7a077cff149589f049bfb452c3b43d2d9fbb3"
    sha256 cellar: :any,                 monterey:       "8a99c6e0c67b86b0e7095bc09253aab161e467be036c7803c2bf109922876baf"
    sha256 cellar: :any,                 big_sur:        "c4ea5beb7f8ddfaf0f563f7f9e2015d75f475547af1aaccc79d69cf6422b09fc"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "31a88b8fcedda31ee10e6d6ab51f1693187fcecb929331896d28b64241aa73ac"
  end

  head do
    url "https://github.com/nabla-c0d3/sslyze.git", branch: "release"

    resource "nassl" do
      url "https://github.com/nabla-c0d3/nassl.git", branch: "release"
    end
  end

  depends_on "pyinvoke" => :build
  depends_on "rust" => :build # for cryptography
  # Project states that it no longer supports Intel based Macs but I don't see why it won't compile
  # depends_on arch: :arm64
  depends_on "pycparser"
  depends_on "python@3.13"
  # according to github this project no longer supports amd64

  uses_from_macos "libffi", since: :catalina

  resource "annotated-types" do
    url "https://files.pythonhosted.org/packages/ee/67/531ea369ba64dcff5ec9c3402f9f51bf748cec26dde048a2f973a4eea7f5/annotated_types-0.7.0.tar.gz"
    sha256 "aff07c09a53a08bc8cfccb9c85b05f1aa9a2a6f23728d790723543408344ce89"
  end

  resource "cffi" do
    url "https://files.pythonhosted.org/packages/fc/97/c783634659c2920c3fc70419e3af40972dbaf758daa229a7d6ea6135c90d/cffi-1.17.1.tar.gz"
    sha256 "1c39c6016c32bc48dd54561950ebd6836e1670f2ae46128f67cf49e789c52824"
  end

  resource "cryptography" do
    url "https://files.pythonhosted.org/packages/91/4c/45dfa6829acffa344e3967d6006ee4ae8be57af746ae2eba1c431949b32c/cryptography-44.0.0.tar.gz"
    sha256 "cd4e834f340b4293430701e772ec543b0fbe6c2dea510a5286fe0acabe153a02"
  end

  resource "pydantic" do
    url "https://files.pythonhosted.org/packages/b7/ae/d5220c5c52b158b1de7ca89fc5edb72f304a70a4c540c84c8844bf4008de/pydantic-2.10.6.tar.gz"
    sha256 "ca5daa827cce33de7a42be142548b0096bf05a7e7b365aebfa5f8eeec7128236"
  end

  resource "pydantic-core" do
    url "https://files.pythonhosted.org/packages/24/23/efff2ea25900c6c0ca3c39603df1768cca512cc3e5193ca217cba164ed6c/pydantic_core-2.28.0.tar.gz"
    sha256 "4aea61530f9fdc8f128a4772c0fdbce9159ecea03201c16fe2e4ba7ebd11b173"
  end

  resource "tls-parser" do
    url "https://files.pythonhosted.org/packages/e8/78/c3e4399f18f734ea3051b1ab1a68bd34b7a8d13fb17b0aadc4c6a1810b10/tls_parser-2.0.1.tar.gz"
    sha256 "9e9f2fdde87a2fda93835f1e18482b8813a1b71958cdb8d5f0cbb9f4ed4e2ec7"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/df/db/f35a00659bc03fec321ba8bce9420de607a1d37f8342eee1863174c69557/typing_extensions-4.12.2.tar.gz"
    sha256 "1a7ead55c7e559dd4dee8856e3a88b41225abfe1ce8df57b7c13915fe121ffb8"
  end

  def install
    venv = virtualenv_create(libexec, "python3.13")
    venv.pip_install resources.reject { |r| r.name == "nassl" }

    ENV.prepend_path "PATH", libexec/"bin"
    resource("nassl").stage do
      system "invoke", "build.all"
      venv.pip_install Pathname.pwd
    end

    venv.pip_install_and_link buildpath
  end


  # tests are currently broken due to an upstream issue with cryptography package: https://github.com/nabla-c0d3/sslyze/issues/656
  test do
    assert_match "SCANS COMPLETED", shell_output("#{bin}/sslyze --mozilla_config=old google.com", 1)
    refute_match("exception", shell_output("#{bin}/sslyze --certinfo letsencrypt.org"))
  end
end
