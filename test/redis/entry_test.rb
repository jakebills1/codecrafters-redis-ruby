require "minitest/autorun"
require_relative '../../lib/redis/entry'

class TestEntry < Minitest::Test
  def setup
    @entry = ::Redis::Entry.new('bar')
    @with_expiry = ::Redis::Entry.new('foo')
    @with_expiry.set_expiry(1)
    @with_long_expiry = ::Redis::Entry.new('foo')
    @with_long_expiry.set_expiry(1_000_000)
  end

  def test_that_entries_without_expiry_do_not_expire
    assert !@entry.expired?
  end

  def test_that_entries_with_expiry_expire
    sleep 1
    assert @with_expiry.expired?
  end

  def test_that_entries_with_long_expiry_do_not_expire
    sleep 1
    assert !@with_long_expiry.expired?
  end
end
