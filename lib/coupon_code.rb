# frozen_string_literal: true

require 'coupon_code/version'
require 'securerandom'
require 'digest/sha1'

module CouponCode
  SYMBOL = '23456789ABCDEFGHJKLMNPQRTUVWXY'
  PARTS  = 3
  PART_LENGTH = 4
  # Separators which will never be placed next to each other.
  # "Curse Word Prevention" algorithm details can be found here
  # https://arcticicestudio.github.io/icecore-hashids/api/curse-word-prevention.html
  # "I" and "S" are removed comparing to original algorithm's list
  # because there are no same characters in the "SYMBOL" list
  CURSE_WORD_SEPARATORS = %w[C F H T U].freeze

  class << self
    def generate(options = {})
      num_parts = options.fetch(:parts, PARTS)
      part_length = options.fetch(:part_length, PART_LENGTH)
      parts = []
      (1..num_parts).each do |part_index|
        parts << generate_safe_code_part(part_index, part_length)
      end
      parts.join('-')
    end

    def standartize(orig, options = {})
      num_parts = options.fetch(:parts, PARTS)
      part_length = options.fetch(:part_length, PART_LENGTH)

      code = orig.upcase
      code.gsub!(/[^#{SYMBOL}]+/, '')
      parts = code.scan(/[#{SYMBOL}]{#{part_length}}/)

      return unless valid?(parts, num_parts, part_length)

      parts.join('-')
    end

    def checkdigit_alg_1(orig, check)
      orig.each_with_index do |c, _|
        k = SYMBOL.index(c)
        check = check * 19 + k
      end
      SYMBOL[check % (SYMBOL.length - 1)]
    end

    private

    def valid?(parts, num_parts, part_length)
      return false if parts.length != num_parts

      parts.each_with_index do |part, i|
        data  = part[0...(part_length - 1)]
        check = part[-1]
        return false if check != checkdigit_alg_1(data.split(''), i + 1)
      end
      true
    end

    def generate_safe_code_part(part_index, part_length)
      loop do
        part = []
        part << next_valid_char(part) until part.length == part_length - 1
        check_digit = checkdigit_alg_1(part, part_index)
        return part.join + check_digit unless invalid_next_char?(part, check_digit)
      end
    end

    def next_valid_char(current_part)
      loop do
        candidate_char = random_symbol
        return candidate_char unless invalid_next_char?(current_part, candidate_char)
      end
    end

    def invalid_next_char?(current_part, next_char)
      CURSE_WORD_SEPARATORS.include?(current_part[-1]) && CURSE_WORD_SEPARATORS.include?(next_char)
    end

    def random_symbol
      SYMBOL[rand(SYMBOL.length)]
    end
  end
end
