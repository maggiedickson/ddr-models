require 'spec_helper'
require 'support/ezid_mock_identifier'

module Ddr::Models
  RSpec.describe HasAdminMetadata, type: :model, contacts: true do

    describe "workflow" do
      let(:collection) { FactoryGirl.create(:collection) }
      let(:item) { FactoryGirl.create(:item) }
      let(:component) { FactoryGirl.create(:component) }
      before do
        item.parent = collection
        item.save!
        component.parent = item
        component.save!
      end

      describe "#published?" do
        subject { collection }
        context "object is published" do
          before { subject.workflow_state = Ddr::Managers::WorkflowManager::PUBLISHED }
          it { is_expected.to be_published }
        end
        context "object workflow is not set" do
          before { subject.workflow_state = nil }
          it { is_expected.not_to be_published }
        end
        context "object is unpublished" do
          before { subject.workflow_state = Ddr::Managers::WorkflowManager::UNPUBLISHED }
          it { is_expected.not_to be_published }
        end
      end

      describe "#unpublished?" do
        subject { collection }
        context "object is published" do
          before { subject.workflow_state = Ddr::Managers::WorkflowManager::PUBLISHED }
          it { is_expected.not_to be_unpublished }
        end
        context "object is unpublished" do
          before { subject.workflow_state = Ddr::Managers::WorkflowManager::UNPUBLISHED }
          it { is_expected.to be_unpublished }
        end
        context "object workflow is not set" do
          before { subject.workflow_state = nil }
          it { is_expected.not_to be_unpublished }
        end
      end

      describe "#publish!" do
        context "do not include descendants" do
          it "should publish and persist the object" do
            collection.publish!(include_descendants: false)
            expect(collection.reload).to be_published
            expect(item.reload).not_to be_published
            expect(component.reload).not_to be_published
          end
        end
        context "do include descendants" do
          it "should publish and persist the object and descendants" do
            collection.publish!
            expect(collection.reload).to be_published
            expect(item.reload).to be_published
            expect(component.reload).to be_published
          end
        end
      end

      describe "#unpublish!" do
        before { collection.publish! }
        it "should unpublish and persist the object and descendants" do
          collection.unpublish!
          expect(collection.reload).not_to be_published
          expect(item.reload).not_to be_published
          expect(component.reload).not_to be_published
        end
      end
    end

    describe "roles" do
      subject { FactoryGirl.build(:item) }

      describe "#copy_resource_roles_from" do
        let(:other) { FactoryGirl.build(:collection) }
        let(:resource_roles) do
          [ FactoryGirl.build(:role, :viewer, :public, :resource),
            FactoryGirl.build(:role, :editor, :group, :resource) ]
        end
        let(:policy_roles) do
          [ FactoryGirl.build(:role, :curator, :person, :policy) ]
        end
        before do
          other.roles.grant *resource_roles
          other.roles.grant *policy_roles
          subject.copy_resource_roles_from(other)
        end
        its(:roles) { should include(*resource_roles) }
        its(:roles) { should_not include(*policy_roles) }
      end

      describe "#grant_roles_to_creator" do
        let(:user) { FactoryGirl.build(:user) }
        before { subject.grant_roles_to_creator(user) }
        its(:roles) { should include(Ddr::Auth::Roles::Role.build(type: "Editor", agent: user.agent, scope: "resource")) }
      end

      describe "persistence" do
        let(:role) { FactoryGirl.build(:role, :downloader, :public) }
        it "should persist the role information" do
          subject.roles.grant role
          subject.save!
          subject.reload
          expect(subject.roles).to contain_exactly(role)
        end
      end

    end

    describe "contacts" do
      subject { FactoryGirl.build(:item) }
      before do
        allow(Ddr::Models::Contact).to receive(:get).with(:find, slug: 'xa') do
          {'id'=>1, 'slug'=>'xa', 'name'=>'Contact A', 'short_name'=>'A'}
        end
        allow(Ddr::Models::Contact).to receive(:get).with(:find, slug: 'yb') do
          {'id'=>1, 'slug'=>'yb', 'name'=>'Contact B', 'short_name'=>'B'}
        end
      end
      describe "#research_help" do
        before { subject.research_help_contact = 'yb' }
        it "should return the appropriate contact" do
          expect(subject.research_help.slug).to eq('yb')
        end
      end
    end

    describe "locking" do
      subject { FactoryGirl.build(:item) }

      describe "#locked?" do
        context "object is locked" do
          before { subject.is_locked = true }
          context "repository is locked" do
            before { Ddr::Models.repository_locked = true }
            after { Ddr::Models.repository_locked = false }
            it "should be true" do
              expect(subject.locked?).to be true
            end
          end
          context "repository is not locked" do
            it "should be true" do
              expect(subject.locked?).to be true
            end
          end
        end
        context "object is not locked" do
          before { subject.is_locked = false }
          context "repository is locked" do
            before { Ddr::Models.repository_locked = true }
            after { Ddr::Models.repository_locked = false }
            it "should be true" do
              expect(subject.locked?).to be true
            end
          end
          context "repository is not locked" do
            it "should be false" do
              expect(subject.locked?).to be false
            end
          end
        end
      end

      describe "lock" do
        it "should lock the object" do
          expect { subject.lock }.to change(subject, :locked?).from(false).to(true)
        end
      end

      describe "unlock" do
        before { subject.lock }
        it "should unlock the object" do
          expect { subject.unlock }.to change(subject, :locked?).from(true).to(false)
        end
      end

      describe "lock!" do
        it "should lock and save the object" do
          subject.lock!
          subject.reload
          expect(subject.locked?).to be true
        end
      end

      describe "unlock!" do
        before { subject.lock! }
        it "should unlock and save the object" do
          subject.unlock!
          subject.reload
          expect(subject.locked?).to be false
        end
      end
    end
  end
end
