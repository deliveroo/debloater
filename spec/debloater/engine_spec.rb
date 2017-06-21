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
    }

    conn.exec %{
      CREATE EXTENSION IF NOT EXISTS pgstattuple;

      CREATE TABLE bloated1 (id bigint primary key, stuff varchar);
      CREATE INDEX idx_bloated1 ON bloated1 (stuff);

      CREATE TABLE bloated2 (id bigint primary key, stuff varchar);
      CREATE INDEX idx_fts ON bloated2 USING gin (to_tsvector('english', stuff));
    }

    (1..1_000).to_a.shuffle.each do |idx|
      conn.exec_params(%{
        INSERT INTO bloated1 VALUES ($1, $2);
      }, [idx, SecureRandom.hex(rand(64) + 63)])
      conn.exec_params(%{
        INSERT INTO bloated2 VALUES ($1, $2);
      }, [idx, SecureRandom.hex(rand(64) + 63)])
    end
  end

  it 'debloats the valid index' do
    result = subject.run
    expect(result.first.name).to eq('idx_bloated1')
  end
end
