module Ddr::Models
  RSpec.describe Indexing do

    subject { obj.index_fields }

    describe "general indexing" do
      let(:obj) { FactoryGirl.build(:item) }

      let(:role1) { FactoryGirl.build(:role, :curator, :person, :resource) }
      let(:role2) { FactoryGirl.build(:role, :curator, :person, :policy) }
      let(:role3) { FactoryGirl.build(:role, :editor, :group, :policy) }
      let(:role4) { FactoryGirl.build(:role, :editor, :person, :policy) }

      before do
        obj.license = "cc-by-nc-nd-40"
        obj.rightsMetadata.license.title = ["License Title"]
        obj.rightsMetadata.license.description = ["License Description"]
        obj.rightsMetadata.license.url = ["http://library.duke.edu"]
        obj.local_id = "foo"
        obj.adminMetadata.doi << "http://doi.org/10.1000/182"
        obj.permanent_id = "ark:/99999/fk4zzz"
        obj.permanent_url = "http://id.library.duke.edu/ark:/99999/fk4zzz"
        obj.display_format = "Image"
        obj.roles.grant role1, role2, role3, role4
        obj.aspace_id = "aspace_dccea43034e1b8261e14cf999e86449d"
      end

      its([Indexing::LICENSE]) { is_expected.to eq("cc-by-nc-nd-40") }
      its([Indexing::LICENSE_TITLE]) { is_expected.to eq("License Title") }
      its([Indexing::LICENSE_DESCRIPTION]) { is_expected.to eq("License Description") }
      its([Indexing::LICENSE_URL]) { is_expected.to eq("http://library.duke.edu") }
      its([Indexing::LOCAL_ID]) { is_expected.to eq("foo") }
      its([Indexing::DOI]) { is_expected.to eq(["http://doi.org/10.1000/182"]) }
      its([Indexing::PERMANENT_ID]) { is_expected.to eq("ark:/99999/fk4zzz") }
      its([Indexing::PERMANENT_URL]) { is_expected.to eq("http://id.library.duke.edu/ark:/99999/fk4zzz") }
      its([Indexing::DISPLAY_FORMAT]) { is_expected.to eq("Image") }
      its([Indexing::ACCESS_ROLE]) { is_expected.to eq(obj.roles.to_json) }
      its([Indexing::POLICY_ROLE]) { is_expected.to contain_exactly(role2.agent.first, role3.agent.first, role4.agent.first) }
      its([Indexing::RESOURCE_ROLE]) { is_expected.to contain_exactly(role1.agent.first) }
      its([Indexing::ASPACE_ID]) { is_expected.to eq("aspace_dccea43034e1b8261e14cf999e86449d") }
    end

    describe "content-bearing object indexing" do
      let(:obj) { FactoryGirl.create(:component) }
      let!(:create_date) { Time.parse("2016-01-22T21:50:33Z") }
      before {
        allow(obj.content).to receive(:createDate) { create_date }
      }

      its([Indexing::CONTENT_CREATE_DATE]) { is_expected.to eq "2016-01-22T21:50:33Z" }
    end

  end
end
