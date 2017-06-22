require 'spec_helper'
require 'debloater/engine'
require 'debloater/connection'
require 'securerandom'

describe Debloater::Engine do
  let(:conn) { Debloater::Connection.new(dbname: 'debloater_test') }

  subject { described_class.new(conn, confirm: false, min_mb: 0, max_density: 1) }

  before do
    conn.exec %{
      DROP TABLE IF EXISTS bloated1;
      DROP TABLE IF EXISTS bloated2;
      DROP TABLE IF EXISTS bloated3;
    }

    conn.exec %{
      CREATE EXTENSION IF NOT EXISTS pgstattuple;

      CREATE TABLE bloated1 (id bigint primary key, stuff varchar);
      CREATE INDEX idx_bloated1 ON bloated1 (stuff);

      CREATE TABLE bloated2 (id bigint primary key, stuff varchar);
      CREATE INDEX idx_fts ON bloated2 USING gin (to_tsvector('english', stuff));

      CREATE TABLE bloated3 (id bigint primary key, stuff bigint);
      CREATE UNIQUE INDEX idx_bloated3 ON bloated3 (stuff);
    }


    %w[bloated1 bloated2].each do |table|
      (1..1_000).to_a.shuffle.each do |id|
        conn.exec_params(%{
          INSERT INTO #{table} VALUES ($1, $2);
        }, [id, SecureRandom.hex(rand(64) + 63)])
      end
    end

    (1..1_000).to_a.shuffle.each_with_index do |id,idx|
      conn.exec_params(%{
        INSERT INTO bloated3 VALUES ($1, $2);
      }, [id, idx])
    end
  end

  it 'debloats the valid indices' do
    result = subject.run
    expect(result.map(&:name)).to eq(%w[idx_bloated1 idx_bloated3])
  end

  it 'creates indices concurrently' do
    allow(conn).to receive(:exec).and_wrap_original do |m, *args|
      sql = args.first
      if sql =~ /CREATE/
        expect(sql).to match(/CONCURRENTLY/)
      end
      m.call(*args)
    end

    subject.run
  end
end
