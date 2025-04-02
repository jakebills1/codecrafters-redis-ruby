# frozen_string_literal: true
require 'minitest/autorun'
require_relative '../../lib/redis/configuration'

module Redis
  class ConfigurationTest < Minitest::Test
    def valid_cl_args
      ['--dir', 'tmp/data', '--dbfilename', 'dump.rdb', '--port', '1234']
    end

    def invalid_cl_args
      ['--foo', 'bar']
    end

    def setup
      @valid_conf = Configuration.new(valid_cl_args)
      @valid_conf.configure!
      @invalid_conf = Configuration.new(invalid_cl_args)
    end

    def test_that_configuration_is_extracted_from_cl_args
      assert @valid_conf.port == 1234, "expected port to be 1234 but was #{@valid_conf.port}"
      assert @valid_conf.dir == 'tmp/data', "expected dir to be /tmp/data but was #{@valid_conf.dir}"
      assert @valid_conf.dbfilename == 'dump.rdb', "expected dbfilename to be dump.rdb but was #{@valid_conf.dbfilename}"
    end

    def test_that_unrecognized_configuration_raises_configuration_error
      assert_raises ConfigurationError do
        @invalid_conf.configure!
      end
    end
  end
end
