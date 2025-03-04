require 'rails_helper'

RSpec.describe ManagerPolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:manager) { Manager.new }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, manager) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index create new update edit edit_program_managers update_managers_mvr_status remove_manager_from_program destroy]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin" }, manager) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index create new update edit edit_program_managers update_managers_mvr_status remove_manager_from_program destroy]) }
  end

  context 'with manager role' do
    let!(:user_manager) { FactoryBot.create(:manager, uniqname: user.uniqname) }
    subject { described_class.new({ user: user_manager, role: "manager" }, manager) }

    it { is_expected.to forbid_actions(%i[index create new update edit edit_program_managers update_managers_mvr_status remove_manager_from_program destroy]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with student role' do
    let!(:user_student) { FactoryBot.create(:student, uniqname: user.uniqname) }
    subject { described_class.new({ user: user_student, role: "student" }, manager) }

    it { is_expected.to forbid_actions(%i[index create new update edit edit_program_managers update_managers_mvr_status remove_manager_from_program destroy]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, manager) }

    it { is_expected.to forbid_all_actions }
  end

end
