require 'test/unit'
require 'wlang'
require 'wlang/rulesets/ruleset_utils'

# Tests the ruleset utilities.
class WLang::RuleSetUtilsTest < Test::Unit::TestCase
  include WLang::RuleSet::Utils
  
  def test_DIALECT_regexp
    assert_not_nil(RG_DIALECT =~ "wlang")
    assert_not_nil(RG_DIALECT =~ "xhtml")
    assert_not_nil(RG_DIALECT =~ "\nxhtml  ")
    assert_not_nil(RG_DIALECT =~ "plain-text")
    assert_nil(RG_DIALECT =~ "wlang/plain-text")
    assert_nil(RG_DIALECT =~ "  wlang/sql  ")
    assert_nil(RG_DIALECT =~ "WLang")
  end
  
  def test_ENCODER_regexp
    assert_not_nil(RG_ENCODER =~ "entities-encoding")
    assert_not_nil(RG_ENCODER =~ "quoting")
    assert_not_nil(RG_ENCODER =~ "\nquoting  ")
    assert_nil(RG_ENCODER =~ "xhtml/entities-encoding")
    assert_nil(RG_ENCODER =~ "  wlang/quoting  ")
    assert_nil(RG_ENCODER =~ "ENCODING")
  end
  
  def test_QDIALECT_regexp
    assert_not_nil(RG_QDIALECT =~ "wlang")
    assert_not_nil(RG_QDIALECT =~ "wlang/plain-text")
    assert_not_nil(RG_QDIALECT =~ "wlang/xhtml")
    assert_not_nil(RG_QDIALECT =~ "wlang/sql")
    assert_not_nil(RG_QDIALECT =~ "  wlang/sql  ")
    assert_not_nil(RG_QDIALECT =~ "wlang/sql/sybase")
    assert_nil(RG_QDIALECT =~ "WLang")
    assert_nil(RG_QDIALECT =~ "wlang/ sql")
    assert_nil(RG_QDIALECT =~ "WLang/sql")
    assert_nil(RG_QDIALECT =~ "wlang/sql/ sybase")
  end
  
  def test_QENCODER_regexp
    assert_not_nil(RG_QENCODER =~ "entities-encoding")
    assert_not_nil(RG_QENCODER =~ "html/entities-encoding")
    assert_not_nil(RG_QENCODER =~ "sql/back-quoting")
    assert_not_nil(RG_QENCODER =~ "sql/back-quoting   ")
    assert_not_nil(RG_QENCODER =~ "sql/sybase/back-quoting")
    assert_nil(RG_QENCODER =~ "sql/ sybase/back-quoting")
  end
  
  def test_VAR_regexp
    assert_not_nil(RG_VAR =~ "name")
    assert_not_nil(RG_VAR =~ "name_with_underscore")
    assert_not_nil(RG_VAR =~ "\nname_with_underscore  \t")
    assert_nil(RG_VAR =~ "\nname _with_underscore  \t")
    tests = [
      [{:variable =>"name"}, "name"],
      [{:variable =>"name_with_underscore"}, "\nname_with_underscore  \t"],
      [nil, "\nname _with_underscore  \t"],
    ]
    tests.each do |t|
      expected, src = t
      assert_equal(expected, WLang::RuleSet::Utils.decode_var(src))
    end
  end
  
  def test_EXPR_regexp
    assert_not_nil(RG_EXPR =~ "name")
    assert_not_nil(RG_EXPR =~ "[12, 13]")
    assert_not_nil(RG_EXPR =~ "Kernel.eval('some expression')")
  end
  
  def test_QDIALECT_AS_regexp
    assert_not_nil(RG_QDIALECT_AS =~ "wlang as x")
    assert_not_nil(RG_QDIALECT_AS =~ "wlang/xhtml as var")
    assert_not_nil(RG_QDIALECT_AS =~ "  wlang/xhtml as var  ")
    assert_nil(RG_QDIALECT_AS =~ "wlang/xhtml")
    assert_nil(RG_QDIALECT_AS =~ "wlang/xhtml as ")
    tests = [
      [{:dialect =>"wlang", :variable => "x"}, "wlang as x"],
      [{:dialect =>"wlang", :variable => "var"}, "  wlang  as  var"],
      [{:dialect =>"wlang/xhtml", :variable => "var"}, "  wlang/xhtml  as  var"],
      [nil, "  wlang  as  "],
    ]
    tests.each do |t|
      expected, src = t
      assert_equal(expected, WLang::RuleSet::Utils.decode_qdialect_as(src))
    end
  end
     
  def test_QENCODER_AS_regexp
    assert_not_nil(RG_QENCODER_AS =~ "entities as x")
    assert_not_nil(RG_QENCODER_AS =~ "html/entities-encoding as var")
    assert_not_nil(RG_QENCODER_AS =~ "  wlang/xhtml/entities-encoding as var  ")
    assert_nil(RG_QENCODER_AS =~ "wlang/entities")
    assert_nil(RG_QENCODER_AS =~ "wlang/quoting as ")
    tests = [
      [{:encoder =>"entities", :variable => "x"}, "entities as x"],
      [{:encoder =>"entities", :variable => "var"}, "  entities  as  var"],
      [{:encoder =>"xhtml/entities-encoding", :variable => "var"}, "  xhtml/entities-encoding  as  var"],
      [nil, "  wlang  as  "],
    ]
    tests.each do |t|
      expected, src = t
      assert_equal(expected, WLang::RuleSet::Utils.decode_qencoder_as(src))
    end
  end
  
  def test_EXPR_AS_regexp
    assert_not_nil(RG_EXPR_AS =~ "name as n")
    assert_not_nil(RG_EXPR_AS =~ "name.upcase as n")
    assert_not_nil(RG_EXPR_AS =~ "[12,13,15] as n")
    assert_not_nil(RG_EXPR_AS =~ "[12,13, 15] as n")
    assert_nil(RG_EXPR_AS =~ "name.upcase")
    tests = [
      [{:expr =>"name", :variable => "n"}, "name as n"],
      [{:expr =>"name.upcase", :variable => "n"}, "name.upcase as n"],
      [{:expr =>"name.upcase", :variable => "n"}, " name.upcase  as  n  "],
      [{:expr =>"name/upcase", :variable => "n"}, " name/upcase  as  n  "],
      [{:expr =>"[12, 15, 276, 'blamebau']", :variable => "n"}, " [12, 15, 276, 'blamebau']  as  n  "],
      [{:expr =>"'what if a as here'", :variable => "n"}, " 'what if a as here'  as  n  "],
    ]
    tests.each do |t|
      expected, src = t
      assert_equal(expected, WLang::RuleSet::Utils.decode_expr_as(src))
    end
  end
  
     
end