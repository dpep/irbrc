require 'minitest/autorun'
load 'lib/irbrc.rb'


class IRBRCTest < Minitest::Test

  def test_parse_repo
    str = "origin git@github.com:dpep/rb_irbrc.git (fetch)"
    assert_equal(
      IRBRC.parse_repo(str),
      {
        source: 'github',
        repo: 'dpep.rb_irbrc.git',
      }
    )


    str = "origin  git@bitbucket.org:danielpepper/bit123.git (fetch)"
    assert_equal(
      IRBRC.parse_repo(str),
      {
        source: 'bitbucket',
        repo: 'danielpepper.bit123.git',
      }
    )
  end

end
