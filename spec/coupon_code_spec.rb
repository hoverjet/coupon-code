# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CouponCode do
  describe '.generate' do
    subject { described_class.generate }

    it { is_expected.not_to be_nil }
    it { is_expected.to match(/^[0-9A-Z-]+$/) }
    it { is_expected.to match(/^\w{4}-\w{4}-\w{4}$/) }
    it 'generates a different code' do
      code2 = described_class.generate
      is_expected.not_to eq(code2)
    end

    context 'when 2 parts' do
      subject { described_class.generate(parts: 2) }
      it { is_expected.to match(/^\w{4}-\w{4}$/) }
    end

    context 'when custom part length' do
      subject { described_class.generate(part_length: 5) }

      it { is_expected.to match(/^[0-9A-Z-]+$/) }
      it { is_expected.to match(/^\w{5}-\w{5}-\w{5}$/) }
    end

    context 'with curse word characters' do
      before do
        # Sequence with a mix of curse word separators and other characters
        # Checkdigit also can be curse word separator, so current part will be regenerated in this case
        allow(CouponCode).to receive(:random_symbol).and_return(*'ABUAFUBCA1FUCP'.chars)
      end

      it 'avoids generating codes with offensive word excluded characters' do
        disallowed_pairs = CouponCode::CURSE_WORD_SEPARATORS.product(CouponCode::CURSE_WORD_SEPARATORS).map(&:join)
        disallowed_regex = Regexp.union(disallowed_pairs)
        is_expected.not_to match(disallowed_regex)
      end
    end
  end

  describe '.validate' do
    it 'validates a good code' do
      expect(described_class.validate('1K7Q-CTFM-LMTC')).to eq('1K7Q-CTFM-LMTC')
    end

    it 'validates and returns the code in uppercase letters' do
      expect(described_class.validate('1K7Q-ctfm-LMTC')).to eq('1K7Q-CTFM-LMTC')
    end

    it 'returns nil for an invalid code' do
      expect(described_class.validate('1K7Q-CTFM')).to be_nil
    end

    it 'handles invalid characters' do
      expect(described_class.validate('OK7Q-CTFM-LMTC')).to be_nil
    end

    context 'valid cases: lowercase, different separator and parts' do
      [
        ['1k7q-ctfm-lmtc'],
        ['1K7Q/CTFM/LMTC'],
        ['1K7Q CTFM LMTC'],
        ['1k7qctfmlmtc'],
        ['1K7Q-CTFM', 2],
        ['7YQH-1FU7-E1HX-0BG9', 4],
        ['YENH-UPJK-PTE0-20U6-QYME', 5],
        ['YENH-UPJK-PTE0-20U6-QYME-RBK1', 6]
      ].each do |args|
        it { expect(described_class.validate(*args)).not_to be_nil }
      end
    end
  end
end
