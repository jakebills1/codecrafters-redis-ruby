# frozen_string_literal: true
require_relative './entry'
require 'pry'
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
      magic_str = io.read(MAGIC_STR_BYTES)
      raise NotAnRDBFile("#{@db_file_path} is not rdb file") unless magic_str.start_with?('REDIS')

      @rdb_version = io.read(RDB_VERSION_BYTES)
      # metadata
      while (opcode = read_int) == OPCODES.fetch('AUX')
        key = read_object
        value = read_object
        metadata[key] = value
      end
      # databases
      while opcode == OPCODES.fetch('SELECTDB')
        db_number = read_length_encoded_int
        db = {}
        # resizedb section
        opcode = read_int
        # db size : length encoded ints
        hash_table_size = read_length_encoded_int
        expiry_table_size = read_length_encoded_int
        while opcode = read_int
          break if opcode.nil? || opcode == OPCODES.fetch('EOF')

          if opcode == OPCODES.fetch('EXPIRETIMEMS') # following k/v has expiry value in ms
            # expiry times are designated widths
            expiry = io.read(8).unpack1('Q')
            enc_value_flag = read_int
          elsif opcode == OPCODES.fetch('EXPIRETIME') # following k/v has expiry value in s
            expiry = io.read(4).unpack1('L')
            enc_value_flag = read_int
          else
            expiry = nil
            enc_value_flag = opcode
          end
          read_key_value_pair(db, enc_value_flag, expiry)
        end
        data << db
      end
    end

    private

    def read_key_value_pair(db, opcode, expiry)
      enc_type = encodings[opcode]
      key_len = read_int
      key = io.read(key_len)
      case enc_type
      when :string
        value_len = read_int
        value = io.read(value_len)
        entry = Entry.new(value)
        entry.expires_at = expiry
        db[key] = entry
      else
        raise "#{opcode} does not map to a registered encoding type"
      end
    end

    attr_reader :io

    # opcodes are always 1 byte
    OPCODES = {
      'AUX' => 250, # 0xFA
      'EOF' => 255, # 0xFF
      'SELECTDB' => 254, # 0xFE
      'EXPIRETIME' => 253, # 0xFD
      'EXPIRETIMEMS' => 252, # 0xFC
      'RESIZEDB' => 251 # 0xFB
    }
    MAGIC_STR_BYTES = 5
    RDB_VERSION_BYTES = 4

    def read_int
      raw = io.read(1)
      return unless raw # read can return nil if EOF was encountered

      raw.unpack1('C')
    end

    def read_length_encoded_int
      read_length[0]
    end

    def read_object
      length, object_type = read_length
      bytes = io.read(length)
      return bytes unless object_type == :integer

      template = case length
                 when 1
                   'C'
                 when 2
                   'S'
                 else
                   'L'
                 end
      bytes.unpack1(template)
    end

    def read_length
      # length encoding:
      # Read one byte from the stream, compare the two most significant bits:
      #
      # Bits	How to parse
      # 00	  The remaining 6 bits represent the length
      # 01	  Read one additional byte. The combined 14 bits represent the length
      # 10	  Discard the remaining 6 bits. The next 4 bytes from the stream represent the length
      # 11	  Variable *
      #
      # * the decimal value of the remaining six bits indicate the number of bytes to read to get the length
      #
      # Dec   Bytes to Read
      # 0     1
      # 1     2
      # 2     4
      raw_read = io.read(1)
      flag = raw_read.ord
      msb = flag >> 6 # get 2 most significant bits
      case msb
      when 0b00
        [flag, :string]
      when 0b01
        raw_read << io.read(1)
        [raw_read.unpack1('S'), :string]
      when 0b10
        [io.read(4).unpack1('L'), :string]
      else
        [integer_length_bytes(flag), :integer]
      end
    end

    def integer_length_bytes(flag)
      case flag & 0b00111111 # get 6 least significant bits
      when 0 # indicates 8 bit integer value follows
        1
      when 1
        2
      when 2
        4
      end
    end

    def encodings
      {
        0 => :string,
      }
    end
  end
end
