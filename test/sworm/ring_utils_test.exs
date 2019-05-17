defmodule Sworm.RingUtilsTest do
  use ExUnit.Case, async: true
  doctest Sworm.RingUtils
  import Sworm.RingUtils

  test "ignore_node?/3 with blacklist" do
    blacklist = [
      ~r/^.+_maint_.*$/
    ]

    # in blacklist
    assert ignore_node?(:"disp1_maint_18090@127.0.0.1", blacklist, [])
    # not in blacklist
    refute ignore_node?(:"disp1_18090@127.0.0.1", blacklist, [])
  end

  test "ignore_node?/3 with whitelist" do
    whitelist = [
      ~r/^disp1.*$/
    ]

    # in whitelist
    refute ignore_node?(:"disp1_maint_18090@127.0.0.1", [], whitelist)
    # not in whitelist
    assert ignore_node?(:"maint_18090@127.0.0.1", [], whitelist)
  end

  test "ignore_node?/3 with whitelist and blacklist" do
    blacklist = [
      ~r/^.+_maint_.*$/
    ]

    whitelist = [
      ~r/^disp1.*$/
    ]

    # only in blacklist
    assert ignore_node?(:"maint_18090@127.0.0.1", blacklist, whitelist)
    # in whitelist and blacklist whitelist takes precedence
    refute ignore_node?(:"disp1_maint_18090@127.0.0.1", blacklist, whitelist)
    # only in whitelist
    refute ignore_node?(:"disp1_18090@127.0.0.1", blacklist, whitelist)
    # neither in blacklist nor in whitelist
    assert ignore_node?(:"18090@127.0.0.1", blacklist, whitelist)
  end

  test "ignore_node?/3 with whitelists and blacklists" do
    blacklist = [
      ~r/^.+_maint1_.*$/,
      ~r/^.+_maint2_.*$/
    ]

    whitelist = [
      ~r/^disp1.*$/,
      ~r/^disp2.*$/
    ]

    # only in blacklist1
    assert ignore_node?(:"disp3_maint1_18090@127.0.0.1", blacklist, whitelist)
    # only in blacklist2
    assert ignore_node?(:"disp3_maint2_18090@127.0.0.1", blacklist, whitelist)
    # in blacklist and whitelist1 whitelist takes precedence
    refute ignore_node?(:"disp1_maint1_18090@127.0.0.1", blacklist, whitelist)
    # in blacklist and whitelist2 whitelist takes precedence
    refute ignore_node?(:"disp2_maint2_18090@127.0.0.1", blacklist, whitelist)
    # only in whitelist1
    refute ignore_node?(:"disp1@127.0.0.1", blacklist, whitelist)
    # only in whitelist2
    refute ignore_node?(:"disp2@127.0.0.1", blacklist, whitelist)
    # neither in blacklist nor in whitelist
    assert ignore_node?(:"18090@127.0.0.1", blacklist, whitelist)
  end
end
