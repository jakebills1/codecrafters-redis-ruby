# frozen_string_literal: true
require 'pry'

module Redis
  class RDBParser
    attr_reader :header, :metadata, :data
    def initialize(db_file_path)
      @db_file_path = db_file_path
      @metadata = {}
      @data = []
      @io = File.open db_file_path, 'rb'
    end

    def parse
      # magic string and redis version number
      @header = io.read(HEADER_BYTES)
      # metadata
      while (opcode = read_opcode) == METADATA_OPCODE
        # length encoding based on 1byte read:
        #   - when the 2 most significant bits are 00,
        #   remaining bits are the length in bytes of
        #   the next object in the stream
        #   - when the 2 most significant bits are 11,
        #   remaining bits indicate size of integer to follow
        #     - 0: 8 bit
        #     - 1: 16 bit
        #     - 2: 32 bit

        # don't think metadata keys can be anything but strings
        key_len = io.read(1).unpack1('C')
        key = io.read(key_len)
        # values might not be encoded as strings
        value = length_encoding
        metadata[key] = value
      end
      # databases
      while opcode == DB_OPCODE
        # database index
        db_number = length_encoding
        db = {}
        # read past the resizedb info
        opcode = read_opcode
        puts "#{opcode} should be FB / 251"
        length_encoding
        # length_encoding
        # next opcode indicates:
        # - a kv pair with a ms expiry
        # - a kv pair with a s expiry
        # - a kv pair with no expiry
        while opcode = read_opcode
          puts "in while loop in db section"
          puts "cursor at #{io.pos}"
          puts "opcode was #{opcode}"
          break if opcode.nil? || opcode == EOF_OPCODE # checksum follows

          case opcode
          when EXPRY_MS_OPCODE # following k/v has expiry value in ms
          when EXPRY_SECONDS_OPCODE # following k/v has expiry value in s
          else # following k/v has no expiry
            enc_type = encodings[opcode]
            key_len = io.read(1).unpack1('C')
            key = io.read(key_len)
            puts enc_type, key, key_len
            case enc_type
            when :string
              value_len = io.read(1).unpack1('C')
              value = io.read(value_len)
              db[key] = value
            end
          end
        end
        data << db
      end
    rescue NoMethodError => e
      puts "At byte offset #{io.pos}"
      puts e.backtrace
    end

    private
    attr_reader :io

    METADATA_OPCODE = 250
    DB_OPCODE = 254
    EOF_OPCODE = 255
    EXPRY_SECONDS_OPCODE = 253
    EXPRY_MS_OPCODE = 252
    HEADER_BYTES = 9

    def read_opcode
      raw = io.read(1)
      return unless raw # read can return nil if EOF was encountered

      raw.unpack1('C')
    end

    def length_encoding
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
