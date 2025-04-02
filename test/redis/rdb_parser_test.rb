# frozen_string_literal: true
require 'minitest/autorun'
require_relative '../../lib/redis/rdb_parser'
class TestRDBParser < Minitest::Test
  def setup
    @parser = ::Redis::RDBParser.new 'dump.rdb'
    @parser.parse
  end

  def test_that_metadata_is_parsed_correctly
    assert @parser.metadata['redis-ver'] == '7.2.6', "expected redis-ver to be 7.2.6, but was #{@parser.metadata['redis-ver']}"
    assert @parser.metadata['redis-bits'] == 64, "expected redis-bits to be 64, but was #{@parser.metadata['redis-bits']}"
  end

  def test_that_multiple_keys_are_parsed
    assert @parser.data.first.keys.sort == ['bar', 'foo'], "expected first data section to have keys foo and bar, but had #{@parser.data.first.keys}"
  end
end