require 'coupon_code/version'
require 'securerandom'
require 'digest/sha1'

module CouponCode
  SYMBOL = '0123456789ABCDEFGHJKLMNPQRTUVWXY'
  PARTS  = 3
  LENGTH = 4
  # Separators which will never be placed next to each other.
  # "Curse Word Prevention" algorithm details can be found here
  # https://arcticicestudio.github.io/icecore-hashids/api/curse-word-prevention.html
  # "I" and "S" are removed comparing to original algorithm's list
  # because there are no same characters in the "SYMBOL" list
  CURSE_WORD_SEPARATORS = %w[C F H T U]

  class << self
    def generate(options = { parts: PARTS })
      num_parts = options.delete(:parts)
      parts = []
      (1..num_parts).each do
        parts << generate_safe_code_part
      end
      parts.join('-')
    end

    def validate(orig, num_parts = PARTS)
      code = orig.upcase
      code.gsub!(/[^#{SYMBOL}]+/, '')
      parts = code.scan(/[#{SYMBOL}]{#{LENGTH}}/)
      return if parts.length != num_parts
      parts.each_with_index do |part, i|
        data  = part[0...(LENGTH - 1)]
        check = part[-1]
        return if check != checkdigit_alg_1(data, i + 1)
      end
      parts.join('-')
    end

    def checkdigit_alg_1(orig, check)
      orig.split('').each_with_index do |c, _|
        k = SYMBOL.index(c)
        check = check * 19 + k
      end
      SYMBOL[check % 31]
    end

    private

    def generate_safe_code_part
      loop do
        part = ''
        until part.length == LENGTH - 1
          part << next_valid_char(part)
        end
        check_digit = checkdigit_alg_1(part, part.length)
        return part + check_digit unless invalid_next_char?(part, check_digit)
      end
    end

    def next_valid_char(current_part)
      loop do
        candidate_char = random_symbol
        return candidate_char unless invalid_next_char?(current_part, candidate_char)
      end
    end

    def invalid_next_char?(current_part, next_char)
      !current_part.empty? && CURSE_WORD_SEPARATORS.include?(current_part[-1]) && CURSE_WORD_SEPARATORS.include?(next_char)
    end

    def random_symbol
      SYMBOL[rand(SYMBOL.length)]
    end
  end
end
