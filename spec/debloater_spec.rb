require "spec_helper"

RSpec.describe Debloater do
  it "has a version number" do
    expect(Debloater::VERSION).not_to be nil
  end
end
