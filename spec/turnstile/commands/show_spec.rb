require 'spec_helper'
require 'turnstile/commands/show'

EXPECTED_NAD_RESPONSE = <<-EOF
turnstile:android#{"\t"}n#{"\t"}3
turnstile:ios#{"\t"}n#{"\t"}2
turnstile:total#{"\t"}n#{"\t"}5
EOF
 .strip

module Turnstile
  module Commands
    RSpec.describe Show do
      let(:options) { { summary: true }}
      subject { described_class.new(options) }

      let(:aggregate) {
        {
          'android' => 3,
          'ios'     => 2,
          'total'   => 5
        }
      }

      describe '#execute' do
        it 'return data in NAD format' do
          expect(subject.nad(aggregate)).to eql(EXPECTED_NAD_RESPONSE)
        end
      end

      describe '#json' do
        let(:json) { subject.json(aggregate) }
        let(:hash) { JSON.load(json) }
        it 'return data in JSON format' do
          expect(hash).to eql(aggregate)
        end
      end
    end
  end
end
