require 'rails_helper'

RSpec.describe Owner, type: :model do
  describe "relations" do
    it { should have_many(:vouchers) }
  end
end
