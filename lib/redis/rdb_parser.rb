# frozen_string_literal: true
require_relative './entry'

module Redis
  class NotAnRDBFile < StandardError; end

  class RDBParser
    attr_reader :rdb_version, :metadata, :data
    def initialize(db_file_path)
      @db_file_path = db_file_path
      @metadata = {}
      @data = []
      @io = File.open db_file_path, 'rb'
    end


    def parse
      # magic string
      magic_str = io.read(MAGIC_STR_BYTES)
      raise NotAnRDBFile("#{@db_file_path} is not rdb file") unless magic_str.start_with?('REDIS')

      # rdb version is 4 bytes
      @rdb_version = io.read(RDB_VERSION_BYTES)
      # metadata
      while (opcode = read_int) == OPCODES.fetch('AUX')
        key_len = read_int
        key = io.read(key_len)
        value = read_next_object
        metadata[key] = value
      end
      # databases
      while opcode == OPCODES.fetch('SELECTDB')
        # database index
        db_number = read_next_object
        db = {}
        # read past the resizedb info
        opcode = read_int
        read_next_object
        while opcode = read_int
          break if opcode.nil? || opcode == OPCODES.fetch('EOF')

          case opcode
          when OPCODES.fetch('EXPIRETIMEMS') # following k/v has expiry value in ms
          when OPCODES.fetch('EXPIRETIME') # following k/v has expiry value in s
          else # following k/v has no expiry
            enc_type = encodings[opcode]
            key_len = read_int
            key = io.read(key_len)
            case enc_type
            when :string
              value_len = read_int
              value = io.read(value_len)
              db[key] = Entry.new(value)
            end
          end
        end
        data << db
      end
    end

    private
    attr_reader :io

    OPCODES = {
      'AUX' => 250,
      'EOF' => 255,
      'SELECTDB' => 254,
      'EXPIRETIME' => 253,
      'EXPIRETIMEMS' => 252,
      'RESIZEDB' => 251
    }
    MAGIC_STR_BYTES = 5
    RDB_VERSION_BYTES = 4

    def read_int
      raw = io.read(1)
      return unless raw # read can return nil if EOF was encountered

      raw.unpack1('C')
    end

    def read_next_object
      # length encoding based on 1byte read:
      #   - when the 2 most significant bits are 00,
      #   remaining bits are the length in bytes of
      #   the next object in the stream
      #   - when the 2 most significant bits are 11,
      #   remaining bits indicate size of integer to follow
      #     - 0: 8 bit
      #     - 1: 16 bit
      #     - 2: 32 bit
      value_len_encoding = io.read(1).ord
      msb = value_len_encoding >> 6 # get 2 most significant bits
      case msb
      when 0b00
        io.read(value_len_encoding)
      when 0b11
        case value_len_encoding & 0b00111111 # get 6 least significant bits
        when 0 # indicates 8 bit integer value follows
          io.read(1).unpack1('C') # 8 bit = 1 byte
        when 1
          io.read(2).unpack1('S')
        when 2
          io.read(4).unpack1('L')
        end
      end
    end

    def encodings
      {
        0 => :string,
      }
    end
  end
end
