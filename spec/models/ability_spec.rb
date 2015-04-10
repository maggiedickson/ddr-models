require 'spec_helper'
require 'cancan/matchers'

module Ddr
  module Auth
    RSpec.describe Ability, type: :model, abilities: true do

      subject { described_class.new(user) }
      let(:user) { FactoryGirl.create(:user) }

      describe "collection permissions" do
        context "user is a collection creator" do
          before { allow(user).to receive(:groups) { [Groups::CollectionCreators] } }
          it { is_expected.to be_able_to(:create, Collection) }
        end

        context "user is not a collection creator" do
          it { is_expected.not_to be_able_to(:create, Collection) }
        end
      end

      describe "#upload_permissions", uploads: true do
        let(:resource) { FactoryGirl.build(:component) }

        context "user has edit permission" do
          before { subject.can(:edit, resource) }
          it { is_expected.to be_able_to(:upload, resource) }
        end

        context "user does not have edit permission" do
          before { subject.cannot(:edit, resource) }
          it { is_expected.not_to be_able_to(:upload, resource) }
        end
      end

      describe "#download_permissions", downloads: true do

        context "on an object" do

          context "which is a Component", components: true do
            let(:resource) { Component.new(pid: "test:1") }

            context "and user does NOT have the downloader role" do
              before do
                allow(subject.current_user).to receive(:has_role?).with(resource, :downloader) { false }
              end

              context "and user has edit permission" do
                before { subject.can :edit, resource }
                it { is_expected.to be_able_to(:download, resource) }
              end

              context "and user has read permission" do
                before do
                  subject.cannot :edit, resource
                  subject.can :read, resource
                end
                it { is_expected.not_to be_able_to(:download, resource) }
              end

              context "and user lacks read permission" do
                before do
                  subject.cannot :edit, resource
                  subject.cannot :read, resource
                end
                it { is_expected.not_to be_able_to(:download, resource) }
              end
            end

            # Component
            context "and user has the downloader role", roles: true do
              before do
                allow(subject.current_user).to receive(:has_role?).with(resource, :downloader) { true }
              end

              context "and user has edit permission" do
                before { subject.can :edit, resource }
                it { is_expected.to be_able_to(:download, resource) }
              end

              context "and user has read permission" do
                before do
                  subject.cannot :edit, resource
                  subject.can :read, resource
                end
                it { is_expected.to be_able_to(:download, resource) }
              end

              context "and user lacks read permission" do
                before do
                  subject.cannot :edit, resource
                  subject.cannot :read, resource
                end
                it { is_expected.not_to be_able_to(:download, resource) }
              end          
            end
          end

          context "which is not a Component" do
            let(:resource) { FactoryGirl.build(:test_content) }

            context "and user has read permission" do
              before do
                subject.cannot :edit, resource
                subject.can :read, resource
              end
              it { is_expected.to be_able_to(:download, resource) }
            end

            context "and user lacks read permission" do
              before do
                subject.cannot :edit, resource
                subject.cannot :read, resource
              end
              it { is_expected.not_to be_able_to(:download, resource) }
            end                  
          end
        end

        context "on a Solr document" do
          let(:resource) { SolrDocument.new(doc) }

          context "for a Component" do
            let(:doc) { {'id'=>'test:1', 'active_fedora_model_ssi'=>'Component'} }

            context "on which the user has the downloader role" do
              before { doc.merge!('admin_metadata__downloader_ssim'=>[user.to_s]) }

              context "but does not have read permission" do
                it { is_expected.not_to be_able_to(:download, resource) }
              end

              context "and has read permission" do
                before { doc.merge!('read_access_person_ssim'=>[user.to_s]) }
                it { is_expected.to be_able_to(:download, resource) }
              end

              context "and has edit permission" do
                before { doc.merge!('edit_access_person_ssim'=>[user.to_s]) }
                it { is_expected.to be_able_to(:download, resource) }
              end
            end

            context "on which the user does NOT have the downloader role" do

              context "and does not have read permission" do
                it { is_expected.not_to be_able_to(:download, resource) }
              end

              context "but has read permission" do
                before { doc.merge!('read_access_person_ssim'=>[user.to_s]) }
                it { is_expected.not_to be_able_to(:download, resource) }
              end

              context "but has edit permission" do
                before { doc.merge!('edit_access_person_ssim'=>[user.to_s]) }
                it { is_expected.to be_able_to(:download, resource) }
              end              
            end
          end

          context "for a non-Component" do
            let(:doc) { {'id'=>'test:1', 'active_fedora_model_ssi'=>'Attachment'} }

            context "on which the user does NOT have read permission" do
              it { is_expected.not_to be_able_to(:download, resource) }
            end

            context "on which the user has read permission" do
              before { doc.merge!('read_access_person_ssim'=>[user.to_s]) }
              it { is_expected.to be_able_to(:download, resource) }
            end

            context "on which the user has edit permission" do
              before { doc.merge!('edit_access_person_ssim'=>[user.to_s]) }
              it { is_expected.to be_able_to(:download, resource) }
            end              
          end
        end

        context "on a datastream", datastreams: true do

          context "named 'content'", content: true do
            let(:resource) { obj.content }
            let(:solr_doc) { SolrDocument.new({id: obj.pid}) }
            before do
              allow(subject).to receive(:solr_doc).with(obj.pid) { solr_doc }
              subject.cannot :edit, obj.pid 
            end

            context "and object is a Component", components: true do
              let(:obj) { Component.new(pid: "test:1") }

              context "and user does not have the downloader role" do            
                before do
                  allow(subject.current_user).to receive(:has_role?).with(solr_doc, :downloader) { false } 
                end

                context "and user has read permission on the object" do
                  before { subject.can :read, obj.pid }
                  it { is_expected.not_to be_able_to(:download, resource) }
                end

                context "and user lacks read permission on the object" do
                  before { subject.cannot :read, obj.pid }
                  it { is_expected.not_to be_able_to(:download, resource) }
                end
              end

              # Component content datastream
              context "and user has the downloader role", roles: true do
                before do
                  allow(subject.current_user).to receive(:has_role?).with(solr_doc, :downloader) { true } 
                end

                context "and user has read permission on the object" do
                  before { subject.can :read, obj.pid }
                  it { is_expected.to be_able_to(:download, resource) }
                end

                context "and user lacks read permission on the object" do
                  before { subject.cannot :read, obj.pid }
                  it { is_expected.not_to be_able_to(:download, resource) }
                end          
              end
            end

            # non-Component content datastream
            context "and object is not a Component" do
              let(:obj) { TestContent.new(pid: "test:1") }

              context "and user has read permission on the object" do
                before { subject.can :read, obj.pid }
                it { is_expected.to be_able_to(:download, resource) }
              end

              context "and user lacks read permission on the object" do
                before { subject.cannot :read, obj.pid }
                it { is_expected.not_to be_able_to(:download, resource) }
              end                  
            end

          end
          # datastream - not "content"
          context "not named 'content'" do
            let(:obj) { FactoryGirl.build(:test_model) }
            let(:resource) { obj.descMetadata }

            context "and user has read permission on the object" do
              before do
                subject.cannot :edit, obj.pid 
                subject.can :read, obj.pid 
              end
              it { is_expected.to be_able_to(:download, resource) }
            end

            context "and user lacks read permission on the object" do
              before do
                subject.cannot :edit, obj.pid 
                subject.cannot :read, obj.pid 
              end
              it { is_expected.not_to be_able_to(:download, resource) }
            end        
          end

        end

      end # download_permissions

      describe "#events_permissions", events: true do
        let(:resource) { Ddr::Events::Event.new(pid: "test:1") }

        context "when the user can read the object" do
          before { subject.can :read, "test:1" }
          it { is_expected.to be_able_to(:read, resource) }
        end

        context "when the user cannot read the object" do
          before { subject.cannot :read, "test:1" }
          it { is_expected.not_to be_able_to(:read, resource) }
        end
      end

      describe "#attachment_permissions", attachments: true do

        context "object can have attachments" do
          let(:resource) { FactoryGirl.build(:test_model_omnibus) }

          context "and user lacks edit rights" do
            before { subject.cannot(:edit, resource) }
            it { is_expected.not_to be_able_to(:add_attachment, resource) }
          end

          context "and user has edit rights" do
            before { subject.can(:edit, resource) }
            it { is_expected.to be_able_to(:add_attachment, resource) }
          end
        end

        context "object cannot have attachments" do
          let(:resource) { FactoryGirl.build(:test_model) }
          before { subject.can(:edit, resource) }
          it { is_expected.not_to be_able_to(:add_attachment, resource) }
        end
      end

      describe "#children_permissions", children: true do

        context "user has edit rights on object" do
          before { subject.can(:edit, resource) }

          context "and object can have children" do
            let(:resource) { FactoryGirl.build(:collection) }
            it { is_expected.to be_able_to(:add_children, resource) }
          end

          context "but object cannot have children" do
            let(:resource) { FactoryGirl.build(:component) }
            it { is_expected.not_to be_able_to(:add_children, resource) }
          end
        end

        context "user lacks edit rights on attached_to object" do
          let(:resource) { FactoryGirl.build(:collection) }
          before { subject.cannot(:edit, resource) }
          it { is_expected.not_to be_able_to(:add_children, resource) }
        end    
      end

    end
  end
end
