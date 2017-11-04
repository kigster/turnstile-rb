require 'spec_helper'
require 'file/tail'
require 'timeout'
require 'thread'
require 'tempfile'

require 'turnstile/collector/log_reader'

describe Turnstile::Collector::LogReader do
  include Timeout

  def consume_file(reader, read_timeout)
    hash    = {}
    counter = 0

    run_reader(read_timeout) do
      reader.read do |token|
        counter     += 1
        hash[token] = 1
      end
    end
    return counter, hash
  end

  def run_reader(read_timeout, &block)
    t_reader = Thread.new do
      begin
        timeout(read_timeout) do
          block.call
        end
      rescue Timeout::Error
      end
    end
    t_reader.join
  end

  let(:queue) { Queue.new }
  let(:read_timeout) { 0.1 }
  let(:consume_file_result) { consume_file(reader, read_timeout) }
  let(:counter) { consume_file_result.first }
  let(:hash) { consume_file_result.last }

  before { reader.file.backward(1000) }

  context 'json log file' do
    let(:file) { 'spec/fixtures/sample-production.log.json' }
    let(:reader) { Turnstile::Collector::LogReader.json_formatted(file, queue) }

    let(:expected_uniques) { 28 }
    let(:expected_total) { 31 }
    let(:expected_key) { 'ipad:69.61.173.104:5462583' }

    context '#read' do
      it 'should be able to read and parse IPs from a static file' do
        expect(counter).to eql(expected_total)
        expect(hash.keys.size).to eql(expected_uniques)
        expect(hash.keys).to include(expected_key)
      end
    end

    context '#process!' do
      it 'should read values into the queue' do
        run_reader(read_timeout) { reader.process! }
        expect(queue.size).to eql(31)
      end
    end
  end

  context 'pipe delimited file' do
    let(:file) { 'spec/fixtures/sample-production.log' }
    let(:reader) { Turnstile::Collector::LogReader.pipe_delimited(file, queue) }

    let(:log_reader) { Turnstile::Collector::LogReader }

    let(:expected_uniques) { 2 }
    let(:expected_total) { 4 }
    let(:expected_key) { 'desktop:124.5.4.3:AF39945f8f87F' }

    context 'matcher' do
      subject(:matcher) { log_reader.delimited_matcher }

      its(:regexp) { should_not be_nil }

      its(:extractor) { should_not be_nil }
      its(:extractor) { should  be_kind_of(Proc) }

      it 'should match lines in the file' do
        File.open(file).each do |line|
          expect(line).to match(matcher.regexp)
        end
      end
      it 'should extract the token from file' do
        File.open(file).each do |line|
          expect(matcher.token_from(line)).to_not be_nil
        end
      end
    end

    context '#read' do
      it 'should be load all matching rows' do
        expect(counter).to eql(expected_total)
        expect(hash.keys.size).to eql(expected_uniques)
        expect(hash.keys).to include(expected_key)
      end
    end

    context '#process!' do
      it 'should read values into the queue' do
        run_reader(read_timeout) { reader.process! }
        expect(queue.size).to eql(expected_total)
      end
    end
  end
end
