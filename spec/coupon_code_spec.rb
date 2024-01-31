# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CouponCode do
  describe '.generate' do
    subject { described_class.generate }

    it { is_expected.not_to be_nil }
    it { is_expected.to match(/^[2-9A-Z-]+$/) }
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

      it { is_expected.to match(/^[2-9A-Z-]+$/) }
      it { is_expected.to match(/^\w{5}-\w{5}-\w{5}$/) }
    end

    context 'with curse word characters' do
      before do
        # Sequence with a mix of curse word separators and other characters
        # Checkdigit also can be curse word separator, so current part will be regenerated in this case
        allow(CouponCode).to receive(:random_symbol).and_return(*'ABUAFUBCA2FUCP'.chars)
      end

      it 'avoids generating codes with offensive word excluded characters' do
        disallowed_pairs = CouponCode::CURSE_WORD_SEPARATORS.product(CouponCode::CURSE_WORD_SEPARATORS).map(&:join)
        disallowed_regex = Regexp.union(disallowed_pairs)
        is_expected.not_to match(disallowed_regex)
      end
    end
  end

  describe '.standartize' do
    it 'standartizes a good code' do
      expect(described_class.standartize('9JRW-QTJ7-3U5G')).to eq('9JRW-QTJ7-3U5G')
    end

    it 'standartizes and returns the code in uppercase letters' do
      expect(described_class.standartize('9jrw-qtj7-3u5g')).to eq('9JRW-QTJ7-3U5G')
    end

    it 'returns nil for an invalid code' do
      expect(described_class.standartize('9jrw-qtj7')).to be_nil
    end

    it 'handles invalid characters' do
      expect(described_class.standartize('9JRF-QTJ7-3U5G')).to be_nil
    end

    context 'when valid cases with lowercase, different separator and parts' do
      [
        ['9jrw-qtj7-3u5g'],
        ['9JRW/QTJ7/3U5G'],
        ['9JRW QTJ7 3U5G'],
        ['9jrwqtj73u5g'],
        ['9JRW-QTJ7', { parts: 2 }],
        ['E36N-R5BL-4XGA-PCNP', { parts: 4 }],
        ['6F94-LD8H-NYP9-J7EW-WEN9', { parts: 5 }],
        ['2TNW-TPCV-4UGB-AQ35-C2W2-MJTW', { parts: 6 }]
      ].each do |args|
        it { expect(described_class.standartize(*args)).not_to be_nil }
      end
    end
  end
end
