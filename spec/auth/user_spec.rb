require 'spec_helper'

module Ddr
  module Auth
    RSpec.describe User, type: :model do

      subject { FactoryGirl.build(:user) }

      describe "#member_of?" do
        before do
          allow(subject).to receive(:groups) { [Group.build("foo"), Group.build("bar")] }
        end
        it "should return true if the user is a member of the group" do
          expect(subject).to be_member_of("foo")
          expect(subject).to be_member_of(Group.build("foo"))
        end
        it "should return false if the user is not a member of the group" do
          expect(subject).not_to be_member_of("baz")
          expect(subject).not_to be_member_of(Group.build("baz"))
        end
      end

      describe "#authorized_to_act_as_superuser?" do
        it "should return false if the superuser group is not defined (nil)" do
          allow(Ddr::Auth).to receive(:superuser_group) { nil }
          expect(subject).not_to be_authorized_to_act_as_superuser
        end
        it "should return false if the user is not a member of the superuser group" do
          allow(subject).to receive(:groups) { [ Group.build("normal") ] }
          expect(subject).not_to be_authorized_to_act_as_superuser
        end
        it "should return true if the user is a member of the superuser group" do
          allow(subject).to receive(:groups) { [ Groups::Superusers ] }
          expect(subject).to be_authorized_to_act_as_superuser
        end
      end

      describe "#principal_name" do
        it "should return the principal name for the user" do
          expect(subject.principal_name).to eq(subject.user_key)
        end
      end

      describe "#agents" do
        it "should be a list of the user's groups + the user as Agent (Person)" do
          allow(subject).to receive(:groups) { [Group.build("foo"), Group.build("bar")] }
          expect(subject.agents).to include(Group.build("foo"), Group.build("bar"), subject.to_agent)
        end
      end

      describe "#to_agent" do
        it "should return a Person agent for the user" do
          expect(subject.to_agent).to eq(Person.build(subject))
        end
      end

      describe "#to_s" do
        it "should return the user's principal name (user_key)" do
          expect(subject.to_s).to eq(subject.principal_name)
          expect(subject.to_s).to eq(subject.eppn)
          expect(subject.to_s).to eq(subject.name)
          expect(subject.to_s).to eq(subject.user_key)
        end
      end

    end
  end
end
