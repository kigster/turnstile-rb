require 'spec_helper'

describe Turnstile::Commands::Summary do
  subject { described_class.new }

  let(:aggregate) {
    {
      'android' => 3,
      'ios'     => 2,
      'total'   => 5
    }
  }

  before { expect(subject).to receive(:aggregate).once.and_return(aggregate) }

  describe '#nad' do
    context 'have some data' do
      let(:expected_string) {
        <<-EOF
turnstile:android#{"\t"}n#{"\t"}3
turnstile:ios#{"\t"}n#{"\t"}2
turnstile:total#{"\t"}n#{"\t"}5
        EOF
      }

      it 'return data in NAD format' do
        expect(subject.nad).to eql(expected_string)
      end
    end
  end

  describe '#json' do
    context 'have some data' do
      let(:json) { subject.json }
      let(:hash) { JSON.load(json) }
      it 'return data in NAD format' do
        expect(hash).to eql(aggregate)
      end
    end
  end
end
