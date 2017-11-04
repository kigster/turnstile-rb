require 'spec_helper'

describe Turnstile::Tracker do

  subject(:tracker) { Turnstile::Tracker.new }

  let(:adapter) { subject.send(:adapter) }

  let(:uid) { 1238438 }
  let(:platform) { :ios }
  let(:ip) { '1.2.3.4' }

  describe '#track_and_sample' do
    it 'calls adapter with correct parameters' do
      expect(adapter).to receive(:add).once.with(uid, platform, ip)
      subject.track_and_sample(uid, platform, ip)
    end

    it 'does not track if sampler returns no' do
      allow(tracker).to receive(:should_track?).and_return false
      expect(adapter).to receive(:add).never
      subject.track_and_sample(uid)
    end
  end

  describe '#track_token' do
    it 'calls adapter with correct parameters' do
      expect(adapter).to receive(:add).once.with(uid.to_s, platform.to_s, ip)
      subject.track_token("#{platform}:#{ip}:#{uid}")
    end
  end

  describe '#track_all' do
    it 'does not track if sampler returns no' do
      expect(adapter).to receive(:add).once
      subject.track_all(uid)
    end
  end
end
