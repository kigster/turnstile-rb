require 'spec_helper'

describe Turnstile::Redis::Adapter, logging: true do
  subject(:adapter) { Turnstile::Redis::Adapter.instance }

  let(:uid) { 1238438 }
  let(:other_uid) { 1238439 }
  let(:another_uid) { 1238440 }
  let(:ip) { '1.2.3.4' }
  let(:another_ip) { '4.3.2.1' }
  let(:platform) { :ios }
  let(:another_platform) { :android }

  context 'with fake redis' do
    let(:redis) { double }

    before do
      allow(adapter).to receive(:with_redis).and_yield(redis)
      expect(redis).to receive(:setex).once.with(key, Turnstile.config.activity_interval, 1)
    end

    describe '#add' do
      let(:key) { adapter.compose_key(uid, platform, ip) }
      it 'calls redis with the correct params' do
        subject.add(uid, platform, ip)
      end
    end
  end

  context 'with real redis' do
    before { adapter.flushdb }
    describe '#fetch' do
      let(:sort_lambda) { ->(a, b) { a[:uid] <=> b[:uid] } }
      let(:expected_hash) do
        [
          { uid: uid.to_s, platform: platform.to_s, ip: ip },
          { uid: other_uid.to_s, platform: platform.to_s, ip: ip },
          { uid: another_uid.to_s, platform: another_platform.to_s, ip: another_ip },
        ]
      end

      before do
        subject.add(uid, platform, ip)
        subject.add(other_uid, platform, ip)
        subject.add(another_uid, another_platform, another_ip)
      end

      it 'pulls the platform specific stats from redis' do
        expect(subject.fetch.sort(&sort_lambda)).to eq(expected_hash.sort(&sort_lambda))
      end
    end

    describe '#aggregate' do
      let(:expected_hash) do
        {
          'android' => 3,
          'ios'     => 2,
          'total'   => 5
        }
      end

      before do
        subject.add(123, :android, ip)
        subject.add(124, :android, ip)
        subject.add(125, :android, ip)

        subject.add(200, :ios, ip)
        subject.add(201, :ios, ip)
      end

      it 'should calculated proper aggregation' do
        expect(subject.aggregate).to eql expected_hash
      end

      its(:aggregate) { should_not include({ 'total' => 0 }) }
      its(:prefix) { should match /^x-turnstile\|\d+/ }

      describe '#flushdb' do
        before { subject.flushdb }
        its(:aggregate) { should include({ 'total' => 0 }) }
      end
    end
  end
end
